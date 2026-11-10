#!/usr/bin/env bash
# Is there work a scheduled run mustn't sleep through? Fork CI runs waiting for approval, or an open,
# non-draft PR whose head is all green, unless a card from the bot (open or done) already names that head.
# Usage: bash pending.sh OWNER/REPO BOT_LOGIN
# Prints one "pending  ..." line per item. Exit 0 something pending, 1 nothing, 2 couldn't tell.
# Callers treat 2 like 0: better a run that finds nothing than work left waiting.
set -uo pipefail
repo=${1:-}; bot=${2:-}
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $bot =~ ^[A-Za-z0-9-]+(\[bot\])?$ ]] || { echo "usage: pending.sh OWNER/REPO BOT_LOGIN" >&2; exit 2; }
b=$(printf '%s' "$bot" | tr '[:upper:]' '[:lower:]')

waiting=$(gh api "repos/$repo/actions/runs?status=action_required&per_page=100" --jq '.workflow_runs[].head_sha') || exit 2
green=$(gh pr list -R "$repo" --state open --limit 200 --json number,isDraft,headRefOid,statusCheckRollup --jq '.[]
  | select((.isDraft | not) and (.statusCheckRollup | length) > 0
    and all(.statusCheckRollup[]; (.conclusion // .state) as $c | $c == "SUCCESS" or $c == "NEUTRAL" or $c == "SKIPPED"))
  | "\(.number) \(.headRefOid)"') || exit 2
# the queue is the oldest open "Waiting for you" issue the bot opened, as act.sh and queue.sh read it
q=$(gh api --paginate "repos/$repo/issues?state=open&labels=githard&per_page=100" --jq ".[] | select(.pull_request == null
  and .title == \"Waiting for you\" and (.user.login|ascii_downcase) == \"$b\") | .number" | sort -n | head -1) || exit 2
heads=""
if [ -n "$q" ]; then
  heads=$(gh api --paginate "repos/$repo/issues/$q/comments?per_page=100" --jq ".[] | select((.user.login|ascii_downcase) == \"$b\")
    | .body | capture(\"^<!-- githard-card id=[0-9a-f]{8} kind=[a-z-]+ target=[0-9]+ head=(?<h>[0-9a-f]{40}) -->\")? | .h") || exit 2
fi

carded() { grep -qxF -- "$1" <<<"$heads"; }
out=1
for h in $(printf '%s\n' "$waiting" | sort -u); do
  carded "$h" || { echo "pending  fork CI waiting for approval at ${h:0:7}"; out=0; }
done
while read -r n h; do
  [ -n "$n" ] || continue
  carded "$h" || { echo "pending  #$n is green at ${h:0:7}"; out=0; }
done <<<"$green"
exit $out
