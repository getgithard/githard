#!/usr/bin/env bash
# The checks CI can run without Claude Code: the manifests parse and agree,
# and every skill and agent has the frontmatter Claude Code needs.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  jq -e . "$f" >/dev/null || { echo "$f: not valid JSON"; fail=1; }
done
name=$(jq -r .name .claude-plugin/plugin.json)
jq -e --arg n "$name" '.plugins[] | select(.name == $n)' .claude-plugin/marketplace.json >/dev/null ||
  { echo "marketplace.json doesn't list the plugin \"$name\""; fail=1; }
for f in skills/*/SKILL.md agents/*.md; do
  [ -e "$f" ] || continue
  [ "$(basename "$f")" = README.md ] && continue
  head -1 "$f" | grep -qx -- '---' || { echo "$f: no frontmatter"; fail=1; continue; }
  for key in name description; do
    sed -n '2,/^---$/p' "$f" | grep -q "^$key:" || { echo "$f: frontmatter has no $key"; fail=1; }
  done
done
# The repo-setup templates, plus a README and a LICENSE, must pass that skill's own audit.
tmp=$(mktemp -d)
cp -R skills/repo-setup/templates/. "$tmp"
touch "$tmp/README.md" "$tmp/LICENSE"
audit=$(cd "$tmp" && bash "$OLDPWD/skills/repo-setup/audit.sh") || true
grep '^missing' <<<"$audit" && { echo "repo-setup templates fail their own audit"; fail=1; }
rm -rf "$tmp"

# Eval cases: each has a tagged prompt and typed graders, and its scaffold runs.
# The evals themselves need Claude credentials, so they run locally (evals/README.md).
for d in evals/*/*/; do
  [[ $d == evals/results/* ]] && continue
  [ -f "$d/prompt.md" ] || { echo "$d: no prompt.md"; fail=1; continue; }
  sed -n '2,/^---$/p' "$d/prompt.md" | grep -q '^tags:' || { echo "$d/prompt.md: no tags"; fail=1; }
  ls "$d"graders/*.md >/dev/null 2>&1 || { echo "$d: no graders"; fail=1; }
  for g in "$d"graders/*.md; do
    [ -e "$g" ] && ! sed -n '2,/^---$/p' "$g" | grep -q '^type:' && { echo "$g: no type"; fail=1; }
  done
  if [ -f "$d/scaffold.sh" ]; then
    s=$(mktemp -d)
    (cd "$s" && bash "$OLDPWD/$d/scaffold.sh") >/dev/null 2>&1 || { echo "$d/scaffold.sh: failed"; fail=1; }
    rm -rf "$s"
  fi
done

# repo-setup's audit flags every gap in its audit-existing scaffold.
s=$(mktemp -d)
audit=$(cd "$s" && bash "$OLDPWD/evals/repo-setup/audit-existing/scaffold.sh" >/dev/null && bash "$OLDPWD/skills/repo-setup/audit.sh") || true
rm -rf "$s"
for item in CONTRIBUTING SECURITY CODE_OF_CONDUCT CODEOWNERS "PR template" "issue templates" \
  "Dependabot watches GitHub Actions" "Dependabot runs monthly" "Dependabot groups updates" \
  "Actions pinned to full commit SHAs" "DCO sign-off check in CI"; do
  grep -q "^missing  $item" <<<"$audit" || { echo "audit.sh didn't flag: $item"; fail=1; }
done
exit $fail
