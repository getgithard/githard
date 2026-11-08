#!/usr/bin/env bash
# Approve the workflow runs waiting on a fork PR, but only those on its current head commit.
# Usage: bash approve-runs.sh OWNER/REPO PR_NUMBER
# A run on an older commit stays waiting, so code pushed after your review still needs a look.
# Read the PR's full diff first. This script doesn't.
set -euo pipefail
repo=${1:?usage: bash approve-runs.sh OWNER/REPO PR_NUMBER}
pr=${2:?usage: bash approve-runs.sh OWNER/REPO PR_NUMBER}
head=$(gh api "repos/$repo/pulls/$pr" --jq .head.sha)
[ -n "$head" ] || { echo "couldn't read the head commit of #$pr"; exit 2; }
echo "head of #$pr is $head"
ids=$(gh api --paginate "repos/$repo/actions/runs?status=action_required&head_sha=$head&per_page=100" --jq '.workflow_runs[].id')
[ -n "$ids" ] || { echo "no runs on $head are waiting for approval"; exit 0; }
for id in $ids; do
  gh api -X POST "repos/$repo/actions/runs/$id/approve" >/dev/null && echo "approved run $id"
done
