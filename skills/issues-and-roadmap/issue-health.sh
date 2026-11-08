#!/usr/bin/env bash
# Check a repo's open issues for the metadata people need to pick one up.
# Usage: bash issue-health.sh OWNER/REPO [POOL_TARGET]
# One line per open issue that lacks a type, a milestone, or a "Done when" line.
# Then the pool: open, unassigned issues labelled "good first issue" or "help wanted"
# that say "Done when". Below POOL_TARGET (default 10) it says so and exits 1.
# If GitHub doesn't answer, it says "unknown" and exits 2 rather than reporting a clean repo.
set -uo pipefail
repo=${1:?usage: bash issue-health.sh OWNER/REPO [POOL_TARGET]}
target=${2:-10}
issues=$(gh issue list -R "$repo" --state open --limit 500 \
  --json number,title,body,milestone,assignees,labels,issueType 2>/dev/null) ||
  { echo "unknown  couldn't list issues for $repo"; exit 2; }

status=0
lines=$(jq -r '.[] |
  [ (if .issueType == null then "no type" else empty end),
    (if .milestone == null then "no milestone" else empty end),
    (if ((.body // "") | test("done when"; "i")) then empty else "no \"Done when\"" end) ] as $gaps
  | select($gaps | length > 0)
  | "needs    #\(.number) \(.title[0:60])  (\($gaps | join(", ")))"' <<<"$issues")
[ -n "$lines" ] && { echo "$lines"; status=1; }

pool=$(jq '[.[] | select((.assignees | length) == 0)
  | select(any(.labels[]; .name == "good first issue" or .name == "help wanted"))
  | select((.body // "") | test("done when"; "i"))] | length' <<<"$issues")
if [ "$pool" -lt "$target" ]; then
  echo "pool     $pool ready to pick up, target $target: scope $((target - pool)) more"; status=1
else
  echo "pool     $pool ready to pick up, target $target"
fi
exit $status
