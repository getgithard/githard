#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# Where a repo's visitors came from over the last 14 days, and the pages they read, to judge each channel on results.
# Usage: bash traffic.sh OWNER/REPO [SNAPSHOT_FILE]
# Needs push access (GitHub only shows traffic to people who can push). With SNAPSHOT_FILE, it
# also appends a dated total (with stars) and a dated line per referrer, so a launch can be compared with the weeks around it.
set -uo pipefail
repo=${1:?usage: bash traffic.sh OWNER/REPO [SNAPSHOT_FILE]}
views=$(gh api "repos/$repo/traffic/views" 2>/dev/null) || { echo "unknown  no traffic data for $repo (push access needed)"; exit 2; }
refs=$(gh api "repos/$repo/traffic/popular/referrers" 2>/dev/null) || refs='[]'
stars=$(gh api "repos/$repo" --jq .stargazers_count 2>/dev/null)
# One wording for every line: "1 view from 1 person", "2 views from 2 people".
n='def n(c; one; many): "\(c) \(if c == 1 then one else many end)"; def seen: "\(n(.count; "view"; "views")) from \(n(.uniques; "person"; "people"))";'
jq -r --arg s "$stars" "$n"' "views    \(seen) in 14 days. Stars: \($s)."' <<<"$views"
jq -r "$n"' if length == 0 then "referrers  none yet" else (.[] | "referrer \(.referrer): \(seen)") end' <<<"$refs"
pages=$(gh api "repos/$repo/traffic/popular/paths" 2>/dev/null) || pages='[]'
jq -r "$n"' if length == 0 then "pages    none yet" else (.[:5][] | "page    \(.path): \(seen)") end' <<<"$pages"
if [ -n "${2:-}" ]; then
  d=$(date +%F)
  jq -r --arg d "$d" --arg s "$stars" '"\($d)\t(total, stars \($s))\t\(.count)\t\(.uniques)"' <<<"$views" >> "$2"
  jq -r --arg d "$(date +%F)" '.[] | "\($d)\t\(.referrer)\t\(.count)\t\(.uniques)"' <<<"$refs" >> "$2"
  echo "appended $(jq length <<<"$refs") referrers to $2"
fi
