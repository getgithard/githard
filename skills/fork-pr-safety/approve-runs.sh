#!/usr/bin/env bash
# Approve the workflow runs waiting on a fork PR, but only those on its current head commit.
# Usage: bash approve-runs.sh OWNER/REPO PR_NUMBER [--head SHA]
# A run on an older commit stays waiting, so code pushed after your review still needs a look.
# --head is the commit you read: if the PR's head is anything else, it refuses and exits 2.
# Read the PR's full diff first. This script doesn't.
set -euo pipefail
repo=${1:?usage: bash approve-runs.sh OWNER/REPO PR_NUMBER [--head SHA]}
pr=${2:?usage: bash approve-runs.sh OWNER/REPO PR_NUMBER [--head SHA]}
shift 2; want=""
while [ $# -gt 0 ]; do
  case $1 in --head) [ $# -ge 2 ] || { echo "--head has no value"; exit 2; }; want=$2; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac
done
head=$(gh api "repos/$repo/pulls/$pr" --jq .head.sha)
[ -n "$head" ] || { echo "couldn't read the head commit of #$pr"; exit 2; }
echo "head of #$pr is $head"
[ -z "$want" ] || [ "$head" = "$want" ] || { echo "that isn't $want, the commit that was read, so nothing is approved"; exit 2; }
ids=$(gh api --paginate "repos/$repo/actions/runs?status=action_required&head_sha=$head&per_page=100" --jq '.workflow_runs[].id')
[ -n "$ids" ] || { echo "no runs on $head are waiting for approval"; exit 0; }
for id in $ids; do
  gh api -X POST "repos/$repo/actions/runs/$id/approve" >/dev/null && echo "approved run $id"
done
