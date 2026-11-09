#!/usr/bin/env bash
# Create a GitHub repo if it doesn't exist, and push a local folder's first commit to it. Safe to run again.
# Usage: bash bootstrap-repo.sh OWNER/REPO DIR [--private] [--description "..."]
#   DIR is a git repo with at least one commit on main. Its main goes to the new repo's main.
#   Once main is protected, it pushes nothing: later changes go through pull requests.
# Meant for the owner to run: agents are often, and rightly, blocked from creating public repos.
set -euo pipefail
repo=${1:?usage: bash bootstrap-repo.sh OWNER/REPO DIR [--private] [--description TEXT]}
dir=$(cd "${2:?usage: bash bootstrap-repo.sh OWNER/REPO DIR [--private] [--description TEXT]}" && pwd)
shift 2; vis=--public; desc=""
while [ $# -gt 0 ]; do case $1 in --private) vis=--private; shift ;; --description) desc=$2; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac; done
git -C "$dir" rev-parse --verify -q main >/dev/null || { echo "$dir has no main branch with a commit"; exit 2; }
if gh api "repos/$repo" --silent 2>/dev/null; then echo "exists   $repo"
else gh repo create "$repo" $vis ${desc:+--description "$desc"} >/dev/null; echo "created  $repo"; fi
git -C "$dir" remote get-url origin >/dev/null 2>&1 || git -C "$dir" remote add origin "https://github.com/$repo.git"
if [ "$(gh api "repos/$repo/branches" --jq length 2>/dev/null)" = 0 ]; then
  git -C "$dir" push -q -u origin main && echo "pushed   main to https://github.com/$repo"
else
  echo "skipped  $repo already has commits. Send changes through a pull request."
fi
