#!/usr/bin/env bash
# Show a repo's published OpenSSF Scorecard, check by check, lowest first.
# Usage: bash scorecard-check.sh OWNER/REPO
# Reads api.securityscorecards.dev, which has a result once the Scorecard workflow has run with
# publish_results. Checks only other people can satisfy are marked "needs others", so nobody
# fakes them: a second human reviewer, contributors from other orgs, and a repo's age.
set -uo pipefail
repo=${1:?usage: bash scorecard-check.sh OWNER/REPO}
r=$(curl -sf --max-time 20 "https://api.securityscorecards.dev/projects/github.com/$repo") ||
  { echo "unknown  no published Scorecard for $repo yet. Add the Scorecard workflow and let it run once."; exit 2; }
jq -r '"score    \(.score)/10, from commit \(.repo.commit[0:7]) on \(.date[0:10])"' <<<"$r"
jq -r '.checks | sort_by(.score) | .[] | select(.score < 10) |
  (if (.name | IN("Code-Review", "Contributors", "Maintained")) then "needs others" else "fixable" end) as $kind
  | "\($kind | . + "        "[0:(13 - length)])\(.name): \(if .score < 0 then "n/a" else "\(.score)/10" end). \(.reason)"' <<<"$r"
