#!/usr/bin/env bash
# Copy repo-setup's templates into a repo and fill in every placeholder. Keeps files the repo already has.
# Usage: bash fill-templates.sh DIR --project NAME --repo OWNER/REPO --owner HANDLE --contact "TEXT"
#   --contact finishes "To report a problem, " in CODE_OF_CONDUCT.md, e.g. "email conduct@example.com".
# Prints each file it adds, then any placeholder it couldn't fill. Exits 1 if one is left.
set -uo pipefail
dir=${1:?usage: bash fill-templates.sh DIR --project NAME --repo OWNER/REPO --owner HANDLE --contact TEXT}; shift
project=""; repo=""; owner=""; contact=""
while [ $# -gt 0 ]; do case $1 in --project) project=$2 ;; --repo) repo=$2 ;; --owner) owner=$2 ;; --contact) contact=$2 ;; *) echo "unknown option $1"; exit 2 ;; esac; shift 2; done
[ -n "$project" ] && [ -n "$repo" ] && [ -n "$owner" ] || { echo "--project, --repo and --owner are required"; exit 2; }
src="$(cd "$(dirname "$0")" && pwd)/templates"
report_to=${contact:-"email {{CONTACT_EMAIL}}"}
cd "$dir" || exit 2
(cd "$src" && find . -type f) | while IFS= read -r f; do
  f=${f#./}
  [ -e "$f" ] && { echo "kept     $f"; continue; }
  mkdir -p "$(dirname "$f")"
  # {{OWNER}}/{{REPO}} first, so a repo path never becomes "handle/{{REPO}}".
  sed -e "s#{{OWNER}}/{{REPO}}#$repo#g" -e "s#{{PROJECT}}#$project#g" -e "s#{{OWNER}}#$owner#g" \
      -e "s#email {{CONTACT_EMAIL}}#$report_to#g" "$src/$f" > "$f"
  echo "added    $f"
done
# Workflow expressions like ${{ github.sha }} aren't placeholders.
left=$(grep -rnE '\{\{[A-Z_]+\}\}' . --exclude-dir=.git --exclude-dir=node_modules 2>/dev/null)
[ -z "$left" ] || { echo "unfilled:"; echo "$left"; exit 1; }
