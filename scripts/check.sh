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
exit $fail
