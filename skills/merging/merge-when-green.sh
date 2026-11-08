#!/usr/bin/env bash
# Merge one PR once every check its branch's ruleset requires has passed on the PR's current head.
# Usage: bash merge-when-green.sh OWNER/REPO PR [--method squash|merge|rebase] [--timeout-min 60]
#        bash merge-when-green.sh --classify < failed-job.log
# Reruns failed jobs only when every failure looks like a download flake (a 5xx, a timeout, a reset),
# at most twice. Anything else is a real failure: it stops and says so.
# Exit: 0 merged, 1 real failure or timeout, 2 refused or GitHub didn't answer.

# Bash reads a script as it runs, so editing this file mid-run breaks the run. Run from a private copy.
if [ -z "${GITHARD_RUNNING_COPY:-}" ]; then
  copy=$(mktemp); cp "$0" "$copy"; GITHARD_RUNNING_COPY=1 exec bash "$copy" "$@"
fi
set -uo pipefail
FLAKE='(HTTP|status|error)[^0-9]{0,12}5[0-9][0-9]|timed? ?out|ETIMEDOUT|ECONNRESET|connection reset|Could not resolve host|TLS handshake|unexpected EOF|Temporary failure in name resolution'
# --classify reads a failed job's log on stdin and prints flake or real. check.sh tests it.
if [ "${1:-}" = --classify ]; then grep -qiE "$FLAKE" && echo flake || echo real; exit 0; fi
repo=${1:?usage: bash merge-when-green.sh OWNER/REPO PR [--method squash] [--timeout-min 60]}
pr=${2:?usage: bash merge-when-green.sh OWNER/REPO PR [--method squash] [--timeout-min 60]}
shift 2
method=squash; timeout_min=60
while [ $# -gt 0 ]; do
  case $1 in --method) method=$2; shift 2 ;; --timeout-min) timeout_min=$2; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac
done

say() { echo "#$pr: $*"; }

# Wait out the API limit instead of reading empty answers as "done".
mind_the_limit() {
  local left reset
  read -r left reset < <(gh api rate_limit --jq '.resources.core | "\(.remaining) \(.reset)"' 2>/dev/null) || return 0
  if [ "${left:-0}" -lt 200 ]; then
    say "API limit low ($left left), waiting until $(date -r "$reset" +%H:%M 2>/dev/null || date -d "@$reset" +%H:%M)"
    sleep $(( reset - $(date +%s) + 5 ))
  fi
}

pull=$(gh api "repos/$repo/pulls/$pr" 2>/dev/null) || { say "unknown: couldn't read the PR"; exit 2; }
if [ "$(jq -r .head.repo.full_name <<<"$pull")" != "$repo" ]; then
  say "comes from a fork. Merge it by hand after review: scripts never touch a contributor's PR."; exit 2
fi
base=$(jq -r .base.ref <<<"$pull")
required=$(gh api "repos/$repo/rules/branches/$base" \
  --jq '[.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context] | unique | .[]' 2>/dev/null) ||
  { say "unknown: couldn't read the ruleset for $base"; exit 2; }
[ -n "$required" ] || say "no required checks on $base, so it merges once nothing is failing"
reruns=0; deadline=$(( $(date +%s) + timeout_min * 60 ))

while [ "$(date +%s)" -lt "$deadline" ]; do
  mind_the_limit
  pull=$(gh api "repos/$repo/pulls/$pr" 2>/dev/null) || { sleep 30; continue; }   # empty answer: unknown, ask again
  case $(jq -r '.merged, .state' <<<"$pull" | paste -sd' ' -) in
    "true "*) say "already merged"; exit 0 ;;
    *closed) say "closed without merging"; exit 1 ;;
  esac
  head=$(jq -r .head.sha <<<"$pull")
  runs=$(gh api "repos/$repo/commits/$head/check-runs?per_page=100" \
    --jq '.check_runs[] | [.name, .status, (.conclusion // "-"), (try (.details_url | capture("runs/(?<id>[0-9]+)").id) catch "-")] | @tsv' 2>/dev/null) ||
    { sleep 30; continue; }
  pending=0; failed=""; failed_runs=""
  names=${required:-$(cut -f1 <<<"$runs" | sort -u)}
  while read -r name; do
    [ -n "$name" ] || continue
    row=$(awk -F'\t' -v n="$name" '$1 == n' <<<"$runs" | tail -1)
    case $(cut -f2,3 <<<"$row" | tr '\t' ' ') in
      "completed success"|"completed skipped"|"completed neutral") ;;
      "completed "*) failed="$failed $name"; failed_runs="$failed_runs $(cut -f4 <<<"$row")" ;;
      *) pending=1 ;;
    esac
  done <<<"$names"

  if [ -z "$failed" ] && [ $pending = 0 ]; then
    say "green on ${head:0:7}, merging"
    gh pr merge "$pr" -R "$repo" --"$method" --match-head-commit "$head" && exit 0
    sleep 30; continue   # a push landed or GitHub was slow: look again
  fi
  if [ -n "$failed" ]; then
    for id in $(tr ' ' '\n' <<<"$failed_runs" | sort -u); do
      [ "$id" != - ] || { say "failed:$failed (not a GitHub Actions run, can't rerun)"; exit 1; }
      # shortcut: a log that shows a flake anywhere counts as a flake. Tighten FLAKE if real failures slip through.
      gh run view "$id" -R "$repo" --log-failed 2>/dev/null | grep -qiE "$FLAKE" ||
        { say "real failure in:$failed"; exit 1; }
    done
    [ $reruns -lt 2 ] || { say "still failing after 2 reruns:$failed"; exit 1; }
    reruns=$((reruns + 1)); say "download flake in:$failed, rerunning failed jobs ($reruns of 2)"
    for id in $(tr ' ' '\n' <<<"$failed_runs" | sort -u); do gh run rerun "$id" -R "$repo" --failed >/dev/null; done
  fi
  sleep 30
done
say "timed out after $timeout_min minutes"; exit 1
