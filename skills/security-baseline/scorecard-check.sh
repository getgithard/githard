#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# Show a repo's published OpenSSF Scorecard, check by check, lowest first.
# Usage: bash scorecard-check.sh OWNER/REPO [--min N]
# With --min, it exits 1 when the overall score is below N, so a workflow can catch a drop.
# Reads api.securityscorecards.dev, which has a result once the Scorecard workflow has run with
# publish_results. Checks only other people can satisfy are marked "needs others", so nobody
# fakes them: a second human reviewer, contributors from other orgs, and a repo's age.
set -uo pipefail
repo=${1:?usage: bash scorecard-check.sh OWNER/REPO [--min N]}
min=""
if [ "${2:-}" = --min ]; then
  min=${3:-}; [[ $min =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "--min needs a number from 0 to 10"; exit 2; }
fi
r=$(curl -sf --max-time 20 "https://api.securityscorecards.dev/projects/github.com/$repo") ||
  { echo "unknown  no published Scorecard for $repo yet. Add the Scorecard workflow and let it run once."; exit 2; }
jq -r '"score    \(.score)/10, from commit \(.repo.commit[0:7]) on \(.date[0:10])"' <<<"$r"
jq -r '.checks | sort_by(.score) | .[] | select(.score < 10) |
  (if .score < 0 then "not scored" elif (.name | IN("Code-Review", "Contributors", "Maintained")) then "needs others" else "fixable" end) as $kind
  | "\($kind | . + "        "[0:(13 - length)])\(.name): \(if .score < 0 then "n/a" else "\(.score)/10" end). \(.reason)"' <<<"$r"
[ -z "$min" ] || jq -e --argjson m "$min" '.score >= $m' <<<"$r" >/dev/null ||
  { echo "below    the score is under the minimum of $min"; exit 1; }
