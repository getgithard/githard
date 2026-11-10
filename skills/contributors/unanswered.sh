#!/usr/bin/env bash
# List open PRs and issues from outside contributors that are owed something.
# Usage: bash unanswered.sh OWNER/REPO [--now YYYY-MM-DD]
#   unanswered  no comment or review from a maintainer yet (PRs), an outside issue with no
#               comments at all, or an outside comment with no maintainer reply after it
#               (issues: claims, questions)
#   check-in    no activity for 30+ days: a person should check in
#   decide      no activity for 60+ days: close it, or finish it with credit
# Bots and maintainers' own PRs are skipped. An empty or failed API answer
# means "unknown", never "nothing owed", so it exits 2 instead of 0.
set -uo pipefail
repo=${1:?usage: bash unanswered.sh OWNER/REPO}
now=$(date -u +%s)
[ "${2:-}" = --now ] && now=$(date -u -j -f %Y-%m-%d "$3" +%s 2>/dev/null || date -u -d "$3" +%s)
maint='^(OWNER|MEMBER|COLLABORATOR)$'

prs=$(gh api --paginate "repos/$repo/pulls?state=open&per_page=100" \
  --jq '.[] | select(.user.type != "Bot" and (.author_association | test("'"$maint"'") | not)) | [.number, .user.login, .updated_at, .html_url] | @tsv') ||
  { echo "unknown  couldn't list PRs for $repo"; exit 2; }
# No open PRs is fine, but only if the repo answers; the issue check below still runs.
[ -z "$prs" ] && { gh api "repos/$repo" --jq .full_name >/dev/null 2>&1 || { echo "unknown  no answer for $repo"; exit 2; }; }

days_since() { local t; t=$(date -u -j -f %Y-%m-%dT%H:%M:%SZ "$1" +%s 2>/dev/null || date -u -d "$1" +%s); echo $(( (now - t) / 86400 )); }

status=0
while IFS=$'\t' read -r n who updated url; do
  [ -n "$n" ] || continue
  replies=$( { gh api --paginate "repos/$repo/issues/$n/comments" --jq '.[].author_association' &&
    gh api --paginate "repos/$repo/pulls/$n/reviews" --jq '.[].author_association'; } 2>/dev/null) ||
    { echo "unknown     #$n @$who  couldn't read replies  $url"; status=2; continue; }
  if ! grep -qE "$maint" <<<"$replies"; then echo "unanswered  #$n @$who  $url"; [ $status = 0 ] && status=1; fi
  d=$(days_since "$updated")
  if [ "$d" -ge 60 ]; then echo "decide      #$n @$who  quiet for $d days  $url"; [ $status = 0 ] && status=1
  elif [ "$d" -ge 30 ]; then echo "check-in    #$n @$who  quiet for $d days  $url"; [ $status = 0 ] && status=1; fi
done <<<"$prs"
# An outside issue nobody has commented on yet is owed a first reply.
fresh=$(gh api --paginate "repos/$repo/issues?state=open&per_page=100" --jq '.[] | select(.pull_request == null and .comments == 0
  and .user.type != "Bot" and (.author_association | test("'"$maint"'") | not)) | [.number, .user.login, .html_url] | @tsv' 2>/dev/null) ||
  { echo "unknown     couldn't list issues for $repo"; exit 2; }
while IFS=$'\t' read -r n who url; do
  [ -n "$n" ] || continue
  echo "unanswered  issue #$n @$who  $url"; [ $status = 0 ] && status=1
done <<<"$fresh"
# Issues whose latest comment is from outside, with no maintainer reply after it: a claim or a question nobody answered.
issues=$(gh api --paginate "repos/$repo/issues?state=open&per_page=100" --jq '.[] | select(.pull_request == null and .comments > 0) | .number' 2>/dev/null) ||
  { echo "unknown     couldn't list issues for $repo"; exit 2; }
for n in $issues; do
  # every page, so the latest comment on a long thread isn't lost past the first 100
  last=$(gh api --paginate --slurp "repos/$repo/issues/$n/comments?per_page=100" 2>/dev/null |
    jq -r '[.[][] | select(.user.type != "Bot")] | last | "\(.author_association) \(.user.login) \(.html_url)"') ||
    { echo "unknown     #$n  couldn't read comments"; status=2; continue; }
  read -r assoc who url <<<"$last"
  [ -n "$assoc" ] || continue
  if ! grep -qE "$maint" <<<"$assoc"; then echo "unanswered  issue #$n @$who  $url"; [ $status = 0 ] && status=1; fi
done
exit $status
