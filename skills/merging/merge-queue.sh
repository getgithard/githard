#!/usr/bin/env bash
# Merge several PRs one at a time, in the order given, each once it's green.
# Usage: bash merge-queue.sh OWNER/REPO PR [PR...]
# One runner, never several in parallel: parallel pollers share one API limit and starve each other.
# A PR that fails or times out is reported and skipped. The queue carries on with the next one.
if [ -z "${GITHARD_RUNNING_COPY:-}" ]; then
  copy=$(mktemp); cp "$0" "$copy"; cp "$(dirname "$0")/merge-when-green.sh" "$copy.mwg"
  GITHARD_RUNNING_COPY=1 GITHARD_MWG="$copy.mwg" exec bash "$copy" "$@"
fi
set -uo pipefail
repo=${1:?usage: bash merge-queue.sh OWNER/REPO PR [PR...]}; shift
[ $# -gt 0 ] || { echo "usage: bash merge-queue.sh OWNER/REPO PR [PR...]"; exit 2; }
merged=(); left=()
for pr in "$@"; do
  if GITHARD_RUNNING_COPY=1 bash "$GITHARD_MWG" "$repo" "$pr"; then merged+=("#$pr"); else left+=("#$pr"); fi
done
echo "merged: ${merged[*]:-none}"
echo "not merged: ${left[*]:-none}"
[ ${#left[@]} -eq 0 ]
