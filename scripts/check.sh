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
# Every script a skill ships parses.
for f in skills/*/*.sh; do bash -n "$f" || { echo "$f: syntax error"; fail=1; }; done

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
# An item listed in .github/audit-skip reports as skipped, not missing.
s=$(mktemp -d); mkdir "$s/.github"; echo SECURITY > "$s/.github/audit-skip"
audit=$(cd "$s" && bash "$OLDPWD/skills/repo-setup/audit.sh") || true
rm -rf "$s"
grep -q '^skipped  SECURITY$' <<<"$audit" || { echo "audit.sh ignored .github/audit-skip"; fail=1; }
# merge-when-green.sh reruns download flakes and nothing else.
mwg=skills/merging/merge-when-green.sh
for log in "curl: (22) The requested URL returned error: 503" "Error: connect ETIMEDOUT 140.82.112.4:443" "fatal: unable to access: Could not resolve host: github.com"; do
  [ "$(echo "$log" | bash $mwg --classify)" = flake ] || { echo "merge-when-green.sh missed a flake: $log"; fail=1; }
done
for log in "AssertionError: expected 3 to equal 4" "npm ERR! Missing script: test" "error TS2322: Type 'string' is not assignable"; do
  [ "$(echo "$log" | bash $mwg --classify)" = real ] || { echo "merge-when-green.sh called a real failure a flake: $log"; fail=1; }
done
# audit-docs.sh ignores URLs inside code: they're examples.
s=$(mktemp -d); printf '```\nhttps://example.invalid/x\n```\nSee `https://example.invalid/y`.\n' > "$s/a.md"
[ -z "$(bash skills/docs-honesty/audit-docs.sh "$s" 2>&1)" ] || { echo "audit-docs.sh checked URLs inside code"; fail=1; }
rm -rf "$s"

# audit-docs.sh flags a subcommand and a flag the help text doesn't list, and passes the ones it does.
s=$(mktemp -d); mkdir "$s/docs"
printf '```sh\n$ jot list --json\njot sync --watch\n```\n' > "$s/docs/usage.md"
audit=$(bash skills/docs-honesty/audit-docs.sh "$s/docs" --no-links --tool jot --help-cmd "printf 'list --json'") || true
rm -rf "$s"
grep -q 'jot sync. isn.t in the help' <<<"$audit" && grep -q -- '--watch. isn.t in the help' <<<"$audit" && ! grep -q -- '--json' <<<"$audit" ||
  { echo "audit-docs.sh got the flag check wrong: $audit"; fail=1; }
# openssf-badge: the criteria table has every level's prerequisite, and add-spdx.sh adds then finds nothing to add.
awk -F'\t' '$1=="achieve_silver" && $2=="gold" && $3=="MUST" {found=1} END {exit !found}' skills/openssf-badge/criteria.tsv ||
  { echo "criteria.tsv lost achieve_silver"; fail=1; }
s=$(mktemp -d); here=$PWD
( cd "$s" && git init -q && printf '#!/bin/sh\necho hi\n' > a.sh && git add a.sh &&
  bash "$here/skills/openssf-badge/add-spdx.sh" "Test" MIT >/dev/null && sed -n 1p a.sh | grep -q '^#!' &&
  grep -q 'SPDX-License-Identifier: MIT' a.sh && bash "$here/skills/openssf-badge/add-spdx.sh" "Test" MIT --check ) ||
  { echo "add-spdx.sh didn't add headers cleanly"; fail=1; }
rm -rf "$s"
python3 -c "import ast,sys; ast.parse(open('skills/openssf-badge/csp-headers.py').read())" || { echo "csp-headers.py doesn't parse"; fail=1; }
# agent-toolkit: a TypeScript repo gets the TypeScript language server, and --apply writes only vetted plugins.
s=$(mktemp -d); here=$PWD
( cd "$s" && git init -q && echo '{}' > package.json && echo 'x' > a.ts && git add -A &&
  bash "$here/skills/agent-toolkit/toolkit.sh" . --apply >/dev/null &&
  jq -e '.enabledPlugins["typescript-lsp@claude-plugins-official"] == true' .claude/settings.json >/dev/null ) ||
  { echo "toolkit.sh didn't set up a TypeScript repo"; fail=1; }
rm -rf "$s"
grep -v '^#' skills/agent-toolkit/vetted.tsv | awk -F'\t' 'NF != 5 {bad=1; print "vetted.tsv row has " NF " fields: " $1} END {exit bad}' || fail=1
# fill-templates.sh leaves no placeholder behind.
s=$(mktemp -d); bash skills/repo-setup/fill-templates.sh "$s" --project jot --repo jotco/jot --owner sam --contact "email c@jot.dev" >/dev/null ||
  { echo "fill-templates.sh left a placeholder"; fail=1; }
grep -qx 'To report a problem, email c@jot.dev. Only the maintainers read it.' "$s/CODE_OF_CONDUCT.md" ||
  { echo "fill-templates.sh garbled the contact line: $(grep 'report a problem' "$s/CODE_OF_CONDUCT.md")"; fail=1; }
rm -rf "$s"
# Every tool the Brewfile lists is on the PATH (brew "python@3" provides python3).
while read -r tool; do
  command -v "$tool" >/dev/null || { echo "Brewfile lists $tool, but it isn't installed"; fail=1; }
done < <(sed -nE 's/^brew "([a-z]+)(@3)?".*/\1\2/p' Brewfile | sed 's/^python@3$/python3/')
# on-duty config.sh reads a valid file, refuses the bare template, and warns on risky values.
cfg=skills/on-duty/config.sh; tpl=skills/on-duty/templates/.github/githard.yml
s=$(mktemp -d)
printf 'mode: safe\nidentity: bot\nmonthly_cap_usd: 25\nwait_for_checks: [CodeQL, Scorecard]\n' > "$s/ok.yml"
out=$(bash $cfg "$s/ok.yml" 2>/dev/null) || { echo "config.sh refused a valid file"; fail=1; }
for line in mode=safe chat=approve-first approve_first_count=5 wait_for_checks=CodeQL,Scorecard; do
  grep -qx "$line" <<<"$out" || { echo "config.sh didn't print $line"; fail=1; }
done
grep -q '^invalid  identity' <<<"$(bash $cfg "$tpl" 2>&1 >/dev/null)" || { echo "config.sh accepted the bare template"; fail=1; }
rc=0; bash $cfg "$tpl" >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "config.sh didn't exit 2 on the template"; fail=1; }
printf 'identity: bot\nmonthly_cap_usd: none\n' > "$s/none.yml"
grep -q '^warning' <<<"$(bash $cfg "$s/none.yml" 2>&1 >/dev/null)" || { echo "config.sh didn't warn on monthly_cap_usd: none"; fail=1; }
printf 'identity: bot\nmonthly_cap_usd: 5\nmode: sometimes\n' > "$s/mode.yml"
rc=0; bash $cfg "$s/mode.yml" >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "config.sh accepted mode: sometimes"; fail=1; }
printf 'identity: bot\nmonthly_cap_usd: 5\napprovers: [a b]\n' > "$s/appr.yml"
rc=0; bash $cfg "$s/appr.yml" >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "config.sh accepted approvers: [a b]"; fail=1; }
rc=0; bash $cfg "$s/missing.yml" >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "config.sh didn't exit 2 on a missing file"; fail=1; }
rm -rf "$s"
# on-duty gate.sh: what goes, what waits, and failing safe on bad config.
gate=skills/on-duty/gate.sh; s=$(mktemp -d)
cfgkv() { # mode chat count risky first -> CFG file path
  printf 'mode=%s\nchat=%s\napprove_first_count=%s\nidentity=bot\nrisky_paths_need_human=%s\nwait_for_checks=\napprovers=\nmonthly_cap_usd=25\nfirst_timer_runs_per_day=%s\nrelease_after_days=7\n' "$1" "$2" "$3" "$4" "$5" > "$s/cfg"; echo "$s/cfg"; }
gcase() { # exact match for go/run; "queue <reason>"/"skip <reason>" otherwise; exit code must be 0
  local want=$1 label=$2 got rc=0; shift 2; got=$(bash $gate "$@" 2>&1) || rc=$?
  [ $rc = 0 ] || { echo "gate.sh $label: exit $rc"; fail=1; return; }
  if [ "$want" = go ] || [ "$want" = run ]; then [ "$got" = "$want" ]; else [[ $got == "$want" || $got == "$want "* ]]; fi ||
    { echo "gate.sh $label: wanted '$want', got '$got'"; fail=1; }
}
safe=$(cfgkv safe approve-first 5 true none); cp "$safe" "$s/safe"
auto=$(cfgkv auto approve-first 5 true none); cp "$auto" "$s/auto"
cfgkv safe auto 5 true none >/dev/null; cp "$s/cfg" "$s/safe-chat-auto"
cfgkv safe approve 5 true none >/dev/null; cp "$s/cfg" "$s/safe-chat-approve"
cfgkv auto approve-first 5 false none >/dev/null; cp "$s/cfg" "$s/auto-norisk"
cfgkv safe approve-first 5 true 2 >/dev/null; cp "$s/cfg" "$s/limit2"
printf '.github/workflows/ci.yml\n' > "$s/p-ci"; printf 'src/a.ts\n' > "$s/p-src"; printf 'src/a.ts\ngo.sum\n' > "$s/p-mixed"
for k in ask settings; do gcase queue "$k in auto" decide "$s/auto" $k; done
for m in safe auto; do gcase go "label in $m" decide "$s/$m" label; done
for k in reply react assign; do
  gcase go "$k in auto" decide "$s/auto" $k
  gcase go "$k safe chat=auto" decide "$s/safe-chat-auto" $k
  gcase queue "$k safe chat=approve" decide "$s/safe-chat-approve" $k
  gcase queue "$k approve-first at 4" decide "$s/safe" $k --replies-approved 4
  gcase go "$k approve-first at 5" decide "$s/safe" $k --replies-approved 5
  gcase queue "$k approve-first, no count" decide "$s/safe" $k
done
gcase queue "merge in safe" decide "$s/safe" merge --paths "$s/p-src" --review-required false
gcase go "merge src in auto" decide "$s/auto" merge --paths "$s/p-src" --review-required false
gcase queue "merge workflow in auto" decide "$s/auto" merge --paths "$s/p-ci" --review-required false
gcase queue "merge lockfile among others" decide "$s/auto" merge --paths "$s/p-mixed" --review-required false
gcase go "merge workflow, risky off" decide "$s/auto-norisk" merge --paths "$s/p-ci" --review-required false
gcase queue "merge review required" decide "$s/auto" merge --paths "$s/p-src" --review-required true
: > "$s/p-empty"; printf 'foo.gemspec\n' > "$s/p-gem"; printf 'lib/setup.py\n' > "$s/p-setup"
gcase queue "merge empty paths" decide "$s/auto" merge --paths "$s/p-empty" --review-required false
gcase queue "merge gemspec" decide "$s/auto" merge --paths "$s/p-gem" --review-required false
gcase queue "merge setup.py" decide "$s/auto" merge --paths "$s/p-setup" --review-required false
for f in GNUmakefile makefile Containerfile; do printf 'x/%s\n' $f > "$s/p-$f"; gcase queue "merge $f" decide "$s/auto" merge --paths "$s/p-$f" --review-required false; done
gcase queue "merge without paths" decide "$s/auto" merge --review-required false
gcase queue "merge without review flag" decide "$s/auto" merge --paths "$s/p-src"
gcase queue "release breaking" decide "$s/auto" release --breaking true
gcase go "release auto" decide "$s/auto" release --breaking false
gcase queue "release safe" decide "$s/safe" release --breaking false
for k in close approve-runs publish; do
  gcase queue "$k safe" decide "$s/safe" $k
  gcase go "$k auto" decide "$s/auto" $k
done
gcase "queue unknown kind" "unknown kind" decide "$s/auto" frobnicate
gcase queue "missing CFG" decide "$s/nope" label
printf 'mode=auto\n' > "$s/partial"; gcase queue "partial CFG" decide "$s/partial" label
printf 'mode=yolo\nchat=auto\napprove_first_count=5\nrisky_paths_need_human=true\n' > "$s/garbled"; gcase queue "garbled mode" decide "$s/garbled" reply
printf '<!-- githard -->\nhi\n' > "$s/b-marker"; printf 'hello\n' > "$s/b-plain"
gcase skip "own marker" should-run "$s/safe" --assoc MEMBER --body-file "$s/b-marker" --runs-today 0
gcase skip "first timer at limit" should-run "$s/limit2" --assoc FIRST_TIME_CONTRIBUTOR --body-file "$s/b-plain" --runs-today 2
gcase skip "NONE at limit" should-run "$s/limit2" --assoc NONE --body-file "$s/b-plain" --runs-today 3
gcase run "first timer under limit" should-run "$s/limit2" --assoc FIRST_TIMER --body-file "$s/b-plain" --runs-today 1
gcase run "MEMBER at limit" should-run "$s/limit2" --assoc MEMBER --body-file "$s/b-plain" --runs-today 9
gcase skip "no assoc at limit" should-run "$s/limit2" --body-file "$s/b-plain" --runs-today 50
gcase skip "MANNEQUIN at limit" should-run "$s/limit2" --assoc MANNEQUIN --body-file "$s/b-plain" --runs-today 2
gcase run "CONTRIBUTOR at limit" should-run "$s/limit2" --assoc CONTRIBUTOR --body-file "$s/b-plain" --runs-today 9
gcase run "limit none" should-run "$s/safe" --assoc NONE --body-file "$s/b-plain" --runs-today 99
gcase skip "should-run missing CFG" should-run "$s/nope" --assoc MEMBER --body-file "$s/b-plain" --runs-today 0
gcase skip "should-run missing body" should-run "$s/safe" --assoc MEMBER --body-file "$s/nobody" --runs-today 0
# next-version.sh: stdin commits, LAST_TAG arg
nv=skills/releases/next-version.sh
nvcase() { # want tag stdin
  local got; got=$(printf '%s\n' "$3" | bash $nv "$2" 2>/dev/null || true)
  [ "$got" = "$1" ] || { echo "next-version.sh $2 with '$3': want '$1', got '$got'"; fail=1; }
}
nvcase v0.1.3 v0.1.2 'fix: a'
nvcase v0.2.0 v0.1.2 'feat: b'
nvcase "breaking v1.0.0" v0.1.2 'feat!: c'
nvcase none v0.1.2 'docs: d'
nvcase githard--v0.2.0 githard--v0.1.0 'feat: e'
nvcase v0.1.3 v0.1.2 'perf(core): f'
nvcase v0.2.0 v0.1.2 $'fix: a\nfeat(x): b'
nvcase "breaking v1.0.0" v0.1.2 $'fix: a\n\nBREAKING CHANGE: gone'
nvcase "breaking v3.0.0" v2.4.1 'fix(api)!: x'
nvcase none v0.1.2 'this fix: is prose'
rc=0; printf 'fix: a\n' | bash $nv main >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "next-version.sh accepted a bad tag"; fail=1; }
[ -z "$(printf 'fix: a\n' | bash $nv v1.2 2>/dev/null || true)" ] || { echo "next-version.sh printed for a bad tag"; fail=1; }
nvnl() { # want tag text: stdin without a trailing newline
  local got; got=$(printf '%s' "$3" | bash $nv "$2" 2>/dev/null || true)
  [ "$got" = "$1" ] || { echo "next-version.sh no-newline '$3': want '$1', got '$got'"; fail=1; }
}
nvnl "breaking v2.0.0" v1.2.3 'feat!: x'
nvnl v1.2.4 v1.2.3 'fix: a'
nvcase "breaking v1.0.0" v0.1.2 'BREAKING CHANGE:'
nvcase "breaking v1.0.0" v0.1.2 'BREAKING CHANGE:text'
nvcase "breaking v1.0.0" v0.1.2 'BREAKING-CHANGE: x'
nvcase "breaking v1.0.0" v0.1.2 'Feat!: x'
nvcase v0.1.3 v0.1.2 'FIX: y'
nvcase "breaking v1.0.0" v0.1.2 $'fix: a\n* feat!: b'
nvcase "breaking v1.0.0" v0.1.2 $'fix: a\n- feat!: b'
nvcase v0.2.0 v0.1.2 $'* feat: b'
rc=0; printf 'fix: a\n' | bash $nv v01.2.3 >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "next-version.sh accepted a leading-zero tag"; fail=1; }
rc=0; seq 1 200000 | sed 's/^/fix: /' | bash $nv v1.2.3 >/dev/null 2>&1 || rc=$?; [ $rc = 0 ] || { echo "next-version.sh exit $rc on a long pipe"; fail=1; }
rm -rf "$s"
exit $fail
