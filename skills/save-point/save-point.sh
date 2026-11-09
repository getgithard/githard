#!/usr/bin/env bash
# Draft the facts for a handoff section, so the prose can't drift from what's true.
# Usage: bash save-point.sh OWNER/REPO [OWNER/REPO...]
# Prints a dated Markdown section: your open PRs, workflows still running, outside PRs owed a
# reply, and issues assigned to you, for each repo. Add the prose (what's done, what's next,
# gotchas), then append the section to the handoff file. It only reads, and changes nothing.
set -uo pipefail
[ $# -gt 0 ] || { echo "usage: bash save-point.sh OWNER/REPO [OWNER/REPO...]"; exit 2; }
me=$(gh api user --jq .login 2>/dev/null) || { echo "unknown: gh isn't signed in"; exit 2; }
here=$(cd "$(dirname "$0")/.." && pwd)
echo "## $(date -u '+%Y-%m-%d %H:%M') UTC: <one line on where things stand>"
echo
echo "Done: <what merged or shipped since the last section>"
echo
echo "Next: <the very next step, specific enough to start without asking>"
for repo in "$@"; do
  echo; echo "### $repo"
  gh pr list -R "$repo" --author "$me" --state open --json number,title,headRefName \
    --jq '.[] | "- Open PR #\(.number): \(.title) (`\(.headRefName)`)"' 2>/dev/null || echo "- Open PRs: unknown"
  gh run list -R "$repo" --limit 20 --json status,name,headBranch,databaseId \
    --jq '.[] | select(.status != "completed") | "- Still running: \(.name) on `\(.headBranch)` (run \(.databaseId))"' 2>/dev/null
  owed=$(bash "$here/contributors/unanswered.sh" "$repo" 2>/dev/null); rc=$?
  case $rc in 0) ;; 2) echo "- Owed a reply: unknown" ;; *) sed 's/^/- Owed: /' <<<"$owed" ;; esac
  gh issue list -R "$repo" --assignee "$me" --state open --json number,title \
    --jq '.[] | "- Assigned to me: #\(.number) \(.title)"' 2>/dev/null
done
echo
echo "Gotchas: <anything learned today the next session would trip over>"
