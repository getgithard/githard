#!/usr/bin/env bash
# Show what a project says about AI-assisted contributions, before anyone contributes to it.
# Usage: bash ai-policy-check.sh OWNER/REPO
# Reads the usual policy files and prints each line that mentions AI, with its file.
# It doesn't decide: read the lines, and if the project bans AI help, don't contribute.
# "no policy found" means none of these files mention it, not that AI help is welcome.
set -uo pipefail
repo=${1:?usage: bash ai-policy-check.sh OWNER/REPO}
gh api "repos/$repo" --silent 2>/dev/null || { echo "unknown  couldn't read $repo"; exit 2; }
found=0
for f in AI_POLICY.md AI-POLICY.md .github/AI_POLICY.md CONTRIBUTING.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md CODE_OF_CONDUCT.md .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md README.md; do
  body=$(gh api "repos/$repo/contents/$f" -H "Accept: application/vnd.github.raw" 2>/dev/null) || continue
  hits=$(grep -niE '(^|[^a-z])(AI|A\.I\.|LLMs?|large language|machine[- ]generated|generated code|copilot|chatgpt|claude|gemini|cursor)([^a-z]|$)' <<<"$body" | cut -c1-220)
  [ -n "$hits" ] && { echo "== $f"; echo "$hits"; found=1; }
done
[ $found = 1 ] || echo "no policy found  None of the usual files mention AI. Ask in an issue or discussion before using AI help."
