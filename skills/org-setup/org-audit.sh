#!/usr/bin/env bash
# Audit a GitHub org against GitHard's org-setup checklist.
# Usage: bash org-audit.sh ORG [--skip "ITEM"]...
#   --skip marks an item as off on purpose (such as "verified domain" for an org with no domain):
#   it reports as skipped, never missing.
# Prints ok | missing | unknown per item. Settings only an owner can see come back unknown
# for anyone else, never ok. Exits 1 if anything is missing, 2 if GitHub didn't answer at all.
set -uo pipefail
org=${1:?usage: bash org-audit.sh ORG [--skip ITEM]...}; shift
skips=""
while [ $# -gt 0 ]; do case $1 in --skip) skips+="$2"$'\n'; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac; done
missing=0
report() {
  local state=$1
  [ "$state" = missing ] && grep -qxF "$2" <<<"$skips" && state=skipped
  printf '%-8s %s\n' "$state" "$2"; [ "$state" = missing ] && missing=1; return 0
}
yes_no() { case $2 in true) report ok "$1" ;; false) report missing "$1" ;; *) report unknown "$1 (owner only)" ;; esac; }
has() { [ -n "$2" ] && [ "$2" != null ] && report ok "$1" || report missing "$1"; }

o=$(gh api "orgs/$org" 2>/dev/null) || { echo "unknown  couldn't read org $org"; exit 2; }
has "display name" "$(jq -r .name <<<"$o")"
has "description" "$(jq -r .description <<<"$o")"
has "website" "$(jq -r .blog <<<"$o")"
has "public email" "$(jq -r .email <<<"$o")"
yes_no "verified domain" "$(jq -r .is_verified <<<"$o")"
yes_no "2FA required for members" "$(jq -r .two_factor_requirement_enabled <<<"$o")"
yes_no "sign-off required on web commits" "$(jq -r .web_commit_signoff_required <<<"$o")"
case $(jq -r .default_repository_permission <<<"$o") in
  read|none) report ok "members get read access by default" ;;
  null) report unknown "default member permission (owner only)" ;;
  *) report missing "members get read access by default (it's $(jq -r .default_repository_permission <<<"$o"))" ;;
esac

if gh api "repos/$org/.github" --jq .private 2>/dev/null | grep -qx false; then
  report ok "public .github repo"
  for f in profile/README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md; do
    gh api "repos/$org/.github/contents/$f" --silent 2>/dev/null && report ok ".github has $f" || report missing ".github has $f"
  done
  gh api "repos/$org/.github/contents/.github/ISSUE_TEMPLATE" --silent 2>/dev/null ||
    gh api "repos/$org/.github/contents/ISSUE_TEMPLATE" --silent 2>/dev/null &&
    report ok ".github has default issue templates" || report missing ".github has default issue templates"
else
  report missing "public .github repo (profile README and default community files)"
fi
pins=$(gh api graphql -f query="{organization(login:\"$org\"){pinnedItems{totalCount}}}" --jq .data.organization.pinnedItems.totalCount 2>/dev/null)
case $pins in ''|null) report unknown "pinned repos" ;; 0) report missing "pinned repos" ;; *) report ok "pinned repos ($pins)" ;; esac
exit $missing
