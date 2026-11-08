#!/usr/bin/env bash
# Audit a repo against GitHard's repo-setup checklist.
# Usage: bash audit.sh [owner/repo]   (run from the repo's root)
# File checks always run. GitHub settings are checked only when an owner/repo
# is given and `gh` can reach it; anything it can't confirm is "unknown", never "ok".
# Prints one line per item: ok | missing | skipped | unknown. Exits 1 if anything is missing.
set -uo pipefail
missing=0
# Items listed one per line in .github/audit-skip are off on purpose: reported as "skipped", never "missing".
report() {
  local state=$1
  [ "$state" = missing ] && [ -f .github/audit-skip ] && grep -qxF "$2" .github/audit-skip && state=skipped
  printf '%-8s %s\n' "$state" "$2"; [ "$state" = missing ] && missing=1; return 0
}
has() { for f in "$@"; do [ -e "$f" ] && return 0; done; return 1; }
check_file() { local label=$1; shift; if has "$@"; then report ok "$label"; else report missing "$label"; fi; }

check_file "README" README.md README README.rst
check_file "LICENSE" LICENSE LICENSE.md LICENSE.txt COPYING
check_file "CONTRIBUTING" CONTRIBUTING.md .github/CONTRIBUTING.md docs/CONTRIBUTING.md
check_file "SECURITY" SECURITY.md .github/SECURITY.md docs/SECURITY.md
check_file "CODE_OF_CONDUCT" CODE_OF_CONDUCT.md .github/CODE_OF_CONDUCT.md docs/CODE_OF_CONDUCT.md
check_file "CODEOWNERS" CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS
check_file "PR template" .github/PULL_REQUEST_TEMPLATE.md .github/pull_request_template.md PULL_REQUEST_TEMPLATE.md
check_file "issue templates" .github/ISSUE_TEMPLATE/*.yml .github/ISSUE_TEMPLATE/*.md

dep=$(ls .github/dependabot.yml .github/dependabot.yaml 2>/dev/null | head -1)
if [ -z "$dep" ]; then report missing "Dependabot config"
else
  grep -q 'package-ecosystem: *"\{0,1\}github-actions' "$dep" && report ok "Dependabot watches GitHub Actions" || report missing "Dependabot watches GitHub Actions"
  if grep -q 'interval:' "$dep" && ! grep 'interval:' "$dep" | grep -qv monthly; then
    report ok "Dependabot runs monthly"; else report missing "Dependabot runs monthly"; fi
  grep -q '^ *groups:' "$dep" && report ok "Dependabot groups updates" || report missing "Dependabot groups updates"
fi

wf=$(ls .github/workflows/*.yml .github/workflows/*.yaml 2>/dev/null)
if [ -z "$wf" ]; then report missing "CI workflow"
else
  report ok "CI workflow"
  # Local actions (./) and docker:// images aren't pinned by commit SHA, so skip them.
  unpinned=$(grep -hE '^[[:space:]]*-?[[:space:]]*uses:' $wf | grep -vE '@[0-9a-f]{40}([[:space:]]|$)' | grep -vE 'uses:[[:space:]]*["'\'']?(\./|docker://)' | sed -E 's/^[[:space:]]*-?[[:space:]]*uses:[[:space:]]*//' | sort -u)
  if [ -z "$unpinned" ]; then report ok "Actions pinned to full commit SHAs"
  else report missing "Actions pinned to full commit SHAs: $(echo $unpinned)"; fi
  grep -qiE 'signed-off-by|dco' $wf && report ok "DCO sign-off check in CI" || report missing "DCO sign-off check in CI"
fi

repo=${1:-}
if [ -z "$repo" ] || ! command -v gh >/dev/null || ! gh api "repos/$repo" --jq .full_name >/dev/null 2>&1; then
  for item in "ruleset on the default branch" "private vulnerability reporting" "Discussions" "Dependabot alerts" "sign-off required on web commits"; do
    report unknown "$item (needs gh and an owner/repo)"
  done
  exit $missing
fi

rules=$(gh api "repos/$repo/rules/branches/$(gh api "repos/$repo" --jq .default_branch)" 2>/dev/null)
if [ -z "$rules" ]; then report unknown "ruleset on the default branch"
else
  echo "$rules" | jq -e 'any(.[]; .type == "pull_request")' >/dev/null && report ok "main is PR-only" || report missing "main is PR-only"
  echo "$rules" | jq -e 'any(.[]; .type == "required_status_checks")' >/dev/null && report ok "required status checks" || report missing "required status checks"
  echo "$rules" | jq -e 'any(.[]; .type == "required_status_checks" and .parameters.strict_required_status_checks_policy == true)' >/dev/null &&
    report missing "branches don't have to be up to date (strict policy is on)" || report ok "branches don't have to be up to date"
fi
pvr=$(gh api "repos/$repo/private-vulnerability-reporting" --jq .enabled 2>/dev/null)
case $pvr in true) report ok "private vulnerability reporting" ;; false) report missing "private vulnerability reporting" ;; *) report unknown "private vulnerability reporting" ;; esac
disc=$(gh api "repos/$repo" --jq .has_discussions 2>/dev/null)
case $disc in true) report ok "Discussions" ;; false) report missing "Discussions" ;; *) report unknown "Discussions" ;; esac
if gh api "repos/$repo/vulnerability-alerts" >/dev/null 2>&1; then report ok "Dependabot alerts"; else report missing "Dependabot alerts"; fi
web=$(gh api "repos/$repo" --jq .web_commit_signoff_required 2>/dev/null)
case $web in true) report ok "sign-off required on web commits" ;; false) report missing "sign-off required on web commits" ;; *) report unknown "sign-off required on web commits" ;; esac
exit $missing
