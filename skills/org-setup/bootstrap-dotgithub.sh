#!/usr/bin/env bash
# Create or update an org's public .github repo from a local folder. Safe to run again.
# Usage: bash bootstrap-dotgithub.sh ORG DIR
#   If main is protected, it pushes a branch and opens a PR instead.
#   DIR holds the files: profile/README.md, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md,
#   .github/ISSUE_TEMPLATE/..., and so on. The repo's main branch ends up matching DIR.
# Meant for the org owner to run: creating an org's public repo needs an owner's rights.
set -euo pipefail
org=${1:?usage: bash bootstrap-dotgithub.sh ORG DIR}
dir=$(cd "${2:?usage: bash bootstrap-dotgithub.sh ORG DIR}" && pwd)
[ -f "$dir/profile/README.md" ] || { echo "$dir/profile/README.md is missing"; exit 2; }
if ! gh api "repos/$org/.github" --silent 2>/dev/null; then
  gh repo create "$org/.github" --public --description "Default community files and the profile for $org" >/dev/null
  echo "created $org/.github"
fi
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
gh repo clone "$org/.github" "$work" -- -q 2>/dev/null || git -C "$work" init -q -b main
git -C "$work" remote get-url origin >/dev/null 2>&1 || git -C "$work" remote add origin "https://github.com/$org/.github.git"
rsync -a --delete --exclude .git "$dir/" "$work/"
git -C "$work" add -A
if git -C "$work" diff --cached --quiet; then echo "$org/.github already matches $dir"; exit 0; fi
git -C "$work" commit -q -s -m "chore: update the org profile and default community files"
if git -C "$work" push -q origin HEAD:main 2>/dev/null; then
  echo "pushed to https://github.com/$org/.github"
else
  # main is protected (as it should be once repo-setup has run), so propose the change instead.
  branch="update-$(date +%Y%m%d-%H%M%S)"
  git -C "$work" push -q origin "HEAD:$branch"
  gh pr create -R "$org/.github" --head "$branch" --base main --title "chore: update the org profile and default community files" \
    --body "Made by bootstrap-dotgithub.sh from a local folder."
fi
