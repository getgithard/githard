#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# The checks CI can run without Claude Code: the manifests parse and agree,
# and every skill has the frontmatter Claude Code needs.
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  jq -e . "$f" >/dev/null || { echo "$f: not valid JSON"; fail=1; }
done
name=$(jq -r .name .claude-plugin/plugin.json)
jq -e --arg n "$name" '.plugins[] | select(.name == $n)' .claude-plugin/marketplace.json >/dev/null ||
  { echo "marketplace.json doesn't list the plugin \"$name\""; fail=1; }
for f in skills/*/SKILL.md; do
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
# add-spdx.sh can add lines to itself mid-run without breaking, and every file here outside the
# templates (which go into other people's repos) carries the lines.
s=$(mktemp -d)
( cd "$s" && git init -q && grep -v '^# \(Copyright\|SPDX\)' "$here/skills/openssf-badge/add-spdx.sh" > add-spdx.sh && git add add-spdx.sh &&
  bash add-spdx.sh "Test" MIT >/dev/null 2>&1 && grep -q 'SPDX-License-Identifier: MIT' add-spdx.sh ) || { echo "add-spdx.sh broke while adding lines to itself"; fail=1; }
rm -rf "$s"
bash skills/openssf-badge/add-spdx.sh "James Conway" MIT --check . ':!skills/*/templates/*' || { echo "files above need: bash skills/openssf-badge/add-spdx.sh \"James Conway\" MIT . ':!skills/*/templates/*'"; fail=1; }
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
rc=0; got=$(set -o pipefail; (echo 'feat!: x'; seq 1 8000 | sed 's/^/fix: /') | bash "$nv" v1.2.3 2>/dev/null) || rc=$?
{ [ "$got" = "breaking v2.0.0" ] && [ $rc = 0 ]; } || { echo "next-version.sh on a long pipe: got '$got', exit $rc"; fail=1; }
# unanswered.sh against a stand-in gh that answers "api [--paginate] PATH --jq F" from fixture files.
ud=$(mktemp -d); mkdir "$ud/bin"
cat > "$ud/bin/gh" <<'GH'
#!/usr/bin/env bash
# "api [-X M] [--paginate [--slurp]] PATH" answers from <PATH>.json and "pr list" from pr_list.json,
# with any --jq applied. A fixture holding several arrays stands for several pages. Every call is logged.
# A fixture that isn't JSON is printed as it is, --silent prints nothing, and "release download"
# copies the files in release/ into the -D folder.
printf '%s\n' "$*" >> "$GH_FIXTURES/calls"
s=""; if [ "$1" = api ]; then shift; [ "$1" = -X ] && shift 2; [ "$1" = --paginate ] && shift; [ "$1" = --slurp ] && { s=1; shift; }; key=$1; else key="$1 $2"; fi
f=$GH_FIXTURES/$(printf '%s' "$key" | tr -c 'A-Za-z0-9' _).json; [ -f "$f" ] || exit 1
q=.; quiet=""; d=""; while [ $# -gt 0 ]; do case $1 in --jq) q=$2 ;; --silent) quiet=1 ;; -D) d=$2 ;; esac; shift; done
[ -z "$d" ] || cp "$GH_FIXTURES"/release/* "$d"/
[ -z "$quiet" ] || exit 0
if ! jq -e . "$f" >/dev/null 2>&1; then cat "$f"
elif [ -n "$s" ]; then jq -s . "$f"; else jq -r "$q" "$f"; fi
GH
# curl answers from curl_<URL>.json, so the network is never touched. sleep returns at once.
cat > "$ud/bin/curl" <<'CURL'
#!/usr/bin/env bash
for a; do url=$a; done
f=$GH_FIXTURES/curl_$(printf '%s' "$url" | tr -c 'A-Za-z0-9' _).json; [ -f "$f" ] && cat "$f"
CURL
printf '#!/bin/sh\n:\n' > "$ud/bin/sleep"
chmod +x "$ud/bin/curl" "$ud/bin/sleep"
chmod +x "$ud/bin/gh"
fx() { printf '%s' "$2" > "$ud/$(printf '%s' "$1" | tr -c 'A-Za-z0-9' _).json"; }
fx 'repos/o/r/pulls?state=open&per_page=100' '[]'
fx 'repos/o/r' '{"full_name":"o/r"}'
fx 'repos/o/r/issues?state=open&per_page=100' '[
  {"number":5,"comments":0,"author_association":"NONE","user":{"login":"sam","type":"User"},"html_url":"u5"},
  {"number":6,"comments":0,"author_association":"OWNER","user":{"login":"me","type":"User"},"html_url":"u6"},
  {"number":7,"comments":0,"author_association":"NONE","user":{"login":"dependabot[bot]","type":"Bot"},"html_url":"u7"},
  {"number":8,"comments":0,"author_association":"NONE","user":{"login":"pat","type":"User"},"html_url":"u8","pull_request":{}}]'
got=$(GH_FIXTURES=$ud PATH="$ud/bin:$PATH" bash skills/contributors/unanswered.sh o/r 2>&1) && rc=0 || rc=$?
{ [ $rc = 1 ] && [ "$got" = "unanswered  issue #5 @sam  u5" ]; } ||
  { echo "unanswered.sh on a new outside issue with no comments: exit $rc, got '$got'"; fail=1; }
# the latest comment is read across every page: here it's on page two, and from outside
fx 'repos/o/r/issues?state=open&per_page=100' '[{"number":9,"comments":101,"author_association":"NONE","user":{"login":"sam","type":"User"},"html_url":"u9"}]'
fx 'repos/o/r/issues/9/comments?per_page=100' '[{"author_association":"OWNER","user":{"login":"me","type":"User"},"html_url":"c1"}]
  [{"author_association":"NONE","user":{"login":"sam","type":"User"},"html_url":"c2"},{"author_association":"NONE","user":{"login":"ci","type":"Bot"},"html_url":"c3"}]'
got=$(GH_FIXTURES=$ud PATH="$ud/bin:$PATH" bash skills/contributors/unanswered.sh o/r 2>&1) && rc=0 || rc=$?
{ [ $rc = 1 ] && [ "$got" = "unanswered  issue #9 @sam  c2" ]; } ||
  { echo "unanswered.sh on a reply past the first page: exit $rc, got '$got'"; fail=1; }
# an outside issue whose only comments are from bots is still waiting, and names its author
fx 'repos/o/r/issues?state=open&per_page=100' '[{"number":10,"comments":1,"author_association":"NONE","user":{"login":"sam","type":"User"},"html_url":"u10"},
  {"number":11,"comments":1,"author_association":"NONE","user":{"login":"bot2","type":"Bot"},"html_url":"u11"},
  {"number":12,"comments":1,"author_association":"NONE","user":{"login":"bot2","type":"Bot"},"html_url":"u12"}]'
fx 'repos/o/r/issues/10/comments?per_page=100' '[{"author_association":"NONE","user":{"login":"ci","type":"Bot"},"html_url":"c4"}]'
fx 'repos/o/r/issues/11/comments?per_page=100' '[{"author_association":"NONE","user":{"login":"ci","type":"Bot"},"html_url":"c5"}]'
fx 'repos/o/r/issues/12/comments?per_page=100' '[{"author_association":"NONE","user":{"login":"pat","type":"User"},"html_url":"c6"}]'
got=$(GH_FIXTURES=$ud PATH="$ud/bin:$PATH" bash skills/contributors/unanswered.sh o/r 2>&1) && rc=0 || rc=$?
{ [ $rc = 1 ] && [ "$got" = "unanswered  issue #10 @sam  u10
unanswered  issue #12 @pat  c6" ]; } ||
  { echo "unanswered.sh on issues with only bot comments, or bot-opened: exit $rc, got '$got'"; fail=1; }
A=$(printf 'a%.0s' {1..40})
stub() { GH_FIXTURES=$ud PATH="$ud/bin:$PATH" "$@"; }
# merge-when-green.sh refuses a fork PR: those are merged by hand after fork-pr-safety
H=$(printf 'e%.0s' {1..40})
fx 'repos/o/r/pulls/7' "{\"merged\":false,\"state\":\"open\",\"base\":{\"ref\":\"main\"},\"head\":{\"sha\":\"$H\",\"repo\":{\"full_name\":\"devon/r\"}}}"
fx 'repos/o/r/rules/branches/main' '[]'; fx rate_limit '{"resources":{"core":{"remaining":5000,"reset":0}}}'; fx 'pr merge' '{}'
fx "repos/o/r/commits/$H/check-runs?per_page=100" '{"check_runs":[{"name":"ci","status":"completed","conclusion":"success","details_url":"x/runs/1"}]}'
rc=0; stub bash $mwg o/r 7 --head "$H" --timeout-min 1 >/dev/null 2>&1 || rc=$?
[ $rc = 2 ] || { echo "merge-when-green.sh didn't refuse a fork PR: exit $rc"; fail=1; }
# approve-runs.sh --head approves only at the commit that was read, and refuses once the PR moves on
fx 'repos/o/r/pulls/9' "{\"head\":{\"sha\":\"$H\"}}"; fx "repos/o/r/actions/runs?status=action_required&head_sha=$H&per_page=100" '{"workflow_runs":[{"id":11}]}'
fx 'repos/o/r/actions/runs/11/approve' '{}'
: > "$ud/calls"; rc=0; stub bash skills/fork-pr-safety/approve-runs.sh o/r 9 --head "$A" >/dev/null 2>&1 || rc=$?
{ [ $rc = 2 ] && ! grep -q approve "$ud/calls"; } || { echo "approve-runs.sh approved runs after the head moved: exit $rc"; fail=1; }
: > "$ud/calls"; rc=0; stub bash skills/fork-pr-safety/approve-runs.sh o/r 9 --head "$H" >/dev/null 2>&1 || rc=$?
{ [ $rc = 0 ] && grep -qx 'api -X POST repos/o/r/actions/runs/11/approve' "$ud/calls"; } || { echo "approve-runs.sh --head didn't approve at the head: exit $rc"; fail=1; }
# approve-runs.sh --dry-run names the runs and approves none
: > "$ud/calls"; rc=0; got=$(stub bash skills/fork-pr-safety/approve-runs.sh o/r 9 --head "$H" --dry-run 2>&1) || rc=$?
{ [ $rc = 0 ] && grep -q 'would approve run 11' <<<"$got" && ! grep -q approve "$ud/calls"; } || { echo "approve-runs.sh --dry-run approved runs or didn't list them: exit $rc"; fail=1; }
# unanswered.sh counts quiet days from --now: 45 days back is 45, a second short of 44 is 43
fx 'repos/o/r/issues?state=open&per_page=100' '[]'; fx 'repos/o/r/pulls/20/reviews' '[]'
fx 'repos/o/r/issues/20/comments' '[{"author_association":"MEMBER"}]'
for d in 2026-10-04T00:00:00Z:45 2026-10-05T00:00:01Z:43; do
  fx 'repos/o/r/pulls?state=open&per_page=100' "[{\"number\":20,\"author_association\":\"NONE\",\"user\":{\"login\":\"sam\",\"type\":\"User\"},\"updated_at\":\"${d%:*}\",\"html_url\":\"p20\"}]"
  got=$(stub bash skills/contributors/unanswered.sh o/r --now 2026-11-18 2>&1) || true
  [ "$got" = "check-in    #20 @sam  quiet for ${d##*:} days  p20" ] || { echo "unanswered.sh day count from ${d%:*}: got '$got'"; fail=1; }
done
# traffic.sh lists the five most-visited pages, or says there are none
fx 'repos/o/r/traffic/views' '{"count":9,"uniques":3}'; fx 'repos/o/r/traffic/popular/referrers' '[]'
fx 'repos/o/r/traffic/popular/paths' "[$(for i in 1 2 3 4 5 6; do printf '{"path":"/p%s","count":%s,"uniques":1},' $i $i; done | sed 's/,$//')]"
got=$(stub bash skills/growth/traffic.sh o/r 2>&1 | grep '^page ')
[ "$got" = "$(for i in 1 2 3 4 5; do echo "page    /p$i: $i views from 1 people"; done)" ] || { echo "traffic.sh didn't list five pages: got $got"; fail=1; }
fx 'repos/o/r/traffic/popular/paths' '[]'
stub bash skills/growth/traffic.sh o/r 2>&1 | grep -qx 'pages    none yet' || { echo "traffic.sh didn't say there are no pages yet"; fail=1; }
# scorecard-check.sh --min sets the exit code from the overall score, against a stand-in curl
fx 'curl_https://api.securityscorecards.dev/projects/github.com/o/r' '{"score":7.3,"date":"2026-11-01","repo":{"commit":"abcdef1234"},"checks":[]}'
for c in ":0" "--min 7:0" "--min 7.5:1" "--min ten:2"; do
  read -ra a <<<"${c%:*}"; rc=0; stub bash skills/security-baseline/scorecard-check.sh o/r ${a[@]+"${a[@]}"} >/dev/null 2>&1 || rc=$?
  [ $rc = "${c##*:}" ] || { echo "scorecard-check.sh ${c%:*} on 7.3: exit $rc, wanted ${c##*:}"; fail=1; }
done
# issue-health.sh counts a writers-wanted issue toward the pool
fx 'issue list' '[{"number":3,"title":"Write the sync page","body":"Done when: it ships","milestone":{"title":"M1"},"issueType":{"name":"Task"},"assignees":[],"labels":[{"name":"writers wanted"}]}]'
stub bash skills/issues-and-roadmap/issue-health.sh o/r 1 2>&1 | grep -qx 'pool     1 ready to pick up, target 1' ||
  { echo "issue-health.sh didn't count a writers-wanted issue in the pool"; fail=1; }
# merge-when-green.sh, end to end against the stand-ins: each case is "PR flags:exit:what it prints".
B=$(printf 'b%.0s' {1..40}); fx rate_limit '{"resources":{"core":{"remaining":10,"reset":0}}}'
pr() { fx "repos/o/r/pulls/$1" "{\"merged\":$2,\"state\":\"$3\",\"base\":{\"ref\":\"main\"},\"head\":{\"sha\":\"$4\",\"repo\":{\"full_name\":\"o/r\"}}}"; }
runs() { fx "repos/o/r/commits/$1/check-runs?per_page=100" "{\"check_runs\":[{\"name\":\"ci\",\"status\":\"completed\",\"conclusion\":\"$2\",\"details_url\":\"$3\"}]}"; }
mwg_case() {
  local want_rc=$1 want=$2; shift 2; rc=0; got=$(stub bash $mwg o/r "$@" 2>&1) || rc=$?
  { [ $rc = "$want_rc" ] && grep -q "$want" <<<"$got"; } || { echo "merge-when-green.sh $*: exit $rc, wanted $want_rc and '$want', got: $got"; fail=1; }
}
pr 31 false open "$B"; runs "$B" success x/runs/5
mwg_case 0 "green on bbbbbbb, merging" 31 --require ci --method squash
pr 32 true closed "$B"; mwg_case 0 "already merged" 32
pr 33 false closed "$B"; mwg_case 1 "closed without merging" 33
pr 34 false open "$B"; mwg_case 2 "head moved" 34 --head "$A"
C=$(printf 'c%.0s' {1..40}); pr 35 false open "$C"; runs "$C" failure x/runs/6
fx 'run view' 'AssertionError: expected 3 to equal 4'; mwg_case 1 "real failure in: ci" 35
fx 'run view' 'curl: (22) The requested URL returned error: 503'; fx 'run rerun' '{}'
mwg_case 1 "still failing after 2 reruns: ci" 35
D=$(printf 'd%.0s' {1..40}); pr 36 false open "$D"; runs "$D" failure https://ci.example/build/1
mwg_case 1 "not a GitHub Actions run" 36
mwg_case 1 "timed out after 0 minutes" 31 --timeout-min 0
mwg_case 2 "couldn't read the PR" 99
mwg_case 2 "has no value" 31 --method
mwg_case 2 "unknown option" 31 --colour red
# merge-queue.sh runs them in order and reports both lists.
rc=0; got=$(stub bash skills/merging/merge-queue.sh o/r 32 33 2>&1) || rc=$?
{ [ $rc = 1 ] && grep -q '^merged: #32$' <<<"$got" && grep -q '^not merged: #33$' <<<"$got"; } ||
  { echo "merge-queue.sh: exit $rc, got $got"; fail=1; }
rc=0; stub bash skills/merging/merge-queue.sh o/r >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "merge-queue.sh with no PRs: exit $rc"; fail=1; }

# ai-policy-check.sh prints the lines that mention AI, and never reads silence as permission.
fx 'repos/o/r/contents/CONTRIBUTING.md' $'# Contributing\nRun the tests.\nAI-generated code must be disclosed in the PR.'
got=$(stub bash skills/growth/ai-policy-check.sh o/r 2>&1)
[ "$got" = $'== CONTRIBUTING.md\n3:AI-generated code must be disclosed in the PR.' ] || { echo "ai-policy-check.sh: got '$got'"; fail=1; }
fx 'repos/o/r/contents/CONTRIBUTING.md' 'Run the tests.'
stub bash skills/growth/ai-policy-check.sh o/r 2>&1 | grep -q '^no policy found' || { echo "ai-policy-check.sh didn't say no policy found"; fail=1; }
rc=0; stub bash skills/growth/ai-policy-check.sh o/none >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "ai-policy-check.sh on a missing repo: exit $rc"; fail=1; }

# badge-status.sh: all Met means nothing blocks silver; one unanswered MUST blocks it.
met=$(grep -v '^#' skills/openssf-badge/criteria.tsv | jq -R -s '[split("\n")[] | select(length > 0) | split("\t") | {key: "\(.[0])_status", value: "Met"}] | from_entries + {name: "notes", badge_level: "passing", tiered_percentage: 195}')
fx 'curl_https://www.bestpractices.dev/projects/7.json' "$met"
rc=0; got=$(stub bash skills/openssf-badge/badge-status.sh 7 2>&1) || rc=$?
{ [ $rc = 0 ] && grep -q '^target   silver$' <<<"$got" && grep -q 'nothing blocks silver' <<<"$got"; } || { echo "badge-status.sh with every criterion Met: exit $rc, got $got"; fail=1; }
must=$(awk -F'\t' '$2 == "silver" && $3 == "MUST" {print $1; exit}' skills/openssf-badge/criteria.tsv)
should=$(awk -F'\t' '$2 == "silver" && $3 == "SHOULD" {print $1; exit}' skills/openssf-badge/criteria.tsv)
fx 'curl_https://www.bestpractices.dev/projects/7.json' "$(jq --arg m "${must}_status" --arg s "${should}_status" 'del(.[$m]) | .[$s] = "Unmet"' <<<"$met")"
rc=0; got=$(stub bash skills/openssf-badge/badge-status.sh 7 silver 2>&1) || rc=$?
{ [ $rc = 1 ] && grep -q "^answer    silver   $must" <<<"$got" && grep -q "^should    silver   $should" <<<"$got"; } || { echo "badge-status.sh with $must unanswered: exit $rc, got $got"; fail=1; }
for c in "7 platinum" "8"; do rc=0; read -ra a <<<"$c"; stub bash skills/openssf-badge/badge-status.sh "${a[@]}" >/dev/null 2>&1 || rc=$?
  [ $rc = 2 ] || { echo "badge-status.sh $c: exit $rc, wanted 2"; fail=1; }; done

# check-headers.sh passes hardened headers and names each one a weak site misses.
fx 'curl_https://good.example' $'HTTP/2 301\r\nlocation: /\r\n\r\nHTTP/2 200\r\ncontent-security-policy: default-src \'self\'; script-src \'self\' \'wasm-unsafe-eval\'; frame-ancestors \'none\'\r\nstrict-transport-security: max-age=31536000\r\nx-content-type-options: nosniff\r\nreferrer-policy: strict-origin-when-cross-origin\r\n'
fx 'curl_https://weak.example' $'HTTP/2 200\r\ncontent-security-policy: script-src * \'unsafe-inline\'\r\nstrict-transport-security: max-age=600\r\n'
rc=0; got=$(stub bash skills/openssf-badge/check-headers.sh https://good.example 2>&1) || rc=$?
{ [ $rc = 0 ] && [ "$got" = "ok       every URL sends hardened headers" ]; } || { echo "check-headers.sh on a hardened site: exit $rc, got $got"; fail=1; }
rc=0; got=$(stub bash skills/openssf-badge/check-headers.sh https://weak.example 2>&1) || rc=$?
{ [ $rc = 1 ] && [ "$(grep -c '^missing' <<<"$got")" = 4 ] && grep -q '^note' <<<"$got"; } || { echo "check-headers.sh on a weak site: exit $rc, got $got"; fail=1; }
rc=0; stub bash skills/openssf-badge/check-headers.sh >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "check-headers.sh with no URL: exit $rc"; fail=1; }

# org-audit.sh: a set-up org passes, --skip turns a gap into skipped, and an empty one is flagged.
fx 'orgs/o' '{"name":"O","description":"d","blog":"https://o.example","email":"hi@o.example","is_verified":false,"two_factor_requirement_enabled":true,"web_commit_signoff_required":true,"default_repository_permission":"read"}'
fx 'repos/o/.github' '{"private":false}'; fx 'graphql' '{"data":{"organization":{"pinnedItems":{"totalCount":3}}}}'
for f in profile/README.md CONTRIBUTING.md SECURITY.md CODE_OF_CONDUCT.md .github/ISSUE_TEMPLATE; do fx "repos/o/.github/contents/$f" '{}'; done
rc=0; got=$(stub bash skills/org-setup/org-audit.sh o --skip "verified domain" 2>&1) || rc=$?
{ [ $rc = 0 ] && grep -q '^skipped  verified domain$' <<<"$got" && grep -q '^ok       pinned repos (3)$' <<<"$got" && ! grep -q '^missing' <<<"$got"; } ||
  { echo "org-audit.sh on a set-up org: exit $rc, got $got"; fail=1; }
fx 'orgs/e' '{"name":null,"default_repository_permission":"write"}'; fx 'graphql' '{}'
rc=0; got=$(stub bash skills/org-setup/org-audit.sh e 2>&1) || rc=$?
{ [ $rc = 1 ] && grep -q '^unknown  2FA required for members (owner only)$' <<<"$got" && grep -q "^missing  members get read access by default (it's write)$" <<<"$got" &&
  grep -q '^missing  public .github repo' <<<"$got" && grep -q '^unknown  pinned repos$' <<<"$got"; } || { echo "org-audit.sh on an empty org: exit $rc, got $got"; fail=1; }
for c in "none" "o --colour"; do rc=0; read -ra a <<<"$c"; stub bash skills/org-setup/org-audit.sh "${a[@]}" >/dev/null 2>&1 || rc=$?
  [ $rc = 2 ] || { echo "org-audit.sh $c: exit $rc, wanted 2"; fail=1; }; done

# The bootstrap scripts push to local bare repos standing in for github.com.
mkdir -p "$ud/remote/o"; git init -q --bare "$ud/remote/o/.github.git"; git init -q --bare "$ud/remote/o/new.git"
gitstub() { GIT_CONFIG_COUNT=3 GIT_CONFIG_KEY_0="url.$ud/remote/.insteadOf" GIT_CONFIG_VALUE_0=https://github.com/ \
  GIT_CONFIG_KEY_1=user.name GIT_CONFIG_VALUE_1=Test GIT_CONFIG_KEY_2=user.email GIT_CONFIG_VALUE_2=test@example.com stub "$@"; }
p=$(mktemp -d); mkdir "$p/profile"; echo '# O' > "$p/profile/README.md"; fx 'repo create' '{}'; fx 'pr create' 'https://github.com/o/.github/pull/1'
rm -f "$ud/repos_o__github.json"
got=$(gitstub bash skills/org-setup/bootstrap-dotgithub.sh o "$p" 2>&1)
{ grep -q '^created o/.github$' <<<"$got" && grep -q '^pushed to' <<<"$got" && git -C "$ud/remote/o/.github.git" show main:profile/README.md | grep -q '^# O$'; } ||
  { echo "bootstrap-dotgithub.sh didn't create and push: $got"; fail=1; }
git -C "$ud/remote/o/.github.git" symbolic-ref HEAD refs/heads/main; fx 'repos/o/.github' '{"private":false}'; echo more > "$p/SECURITY.md"
got=$(gitstub bash skills/org-setup/bootstrap-dotgithub.sh o "$p" 2>&1)
grep -q 'pull/1' <<<"$got" || { echo "bootstrap-dotgithub.sh didn't open a PR when main took no push: $got"; fail=1; }
rc=0; gitstub bash skills/org-setup/bootstrap-dotgithub.sh o "$ud/bin" >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "bootstrap-dotgithub.sh without a profile: exit $rc"; fail=1; }
l=$(mktemp -d); git -C "$l" init -q -b main; GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=user.name GIT_CONFIG_VALUE_0=T GIT_CONFIG_KEY_1=user.email GIT_CONFIG_VALUE_1=t@e.x git -C "$l" commit -q --allow-empty -m first
fx 'repos/o/new/branches' '[]'
got=$(gitstub bash skills/repo-setup/bootstrap-repo.sh o/new "$l" --private --description "a notes app" 2>&1)
{ grep -q '^created  o/new$' <<<"$got" && grep -q '^pushed   main' <<<"$got" && git -C "$ud/remote/o/new.git" rev-parse -q --verify main >/dev/null; } ||
  { echo "bootstrap-repo.sh didn't create and push: $got"; fail=1; }
fx 'repos/o/new' '{}'; fx 'repos/o/new/branches' '[{"name":"main"}]'
got=$(gitstub bash skills/repo-setup/bootstrap-repo.sh o/new "$l" 2>&1)
{ grep -q '^exists   o/new$' <<<"$got" && grep -q '^skipped' <<<"$got"; } || { echo "bootstrap-repo.sh pushed to a repo with commits: $got"; fail=1; }
for c in "--colour" ""; do rc=0; e=$(mktemp -d); git -C "$e" init -q; read -ra a <<<"$c"
  gitstub bash skills/repo-setup/bootstrap-repo.sh o/new "$([ -z "$c" ] && echo "$e" || echo "$l")" ${a[@]+"${a[@]}"} >/dev/null 2>&1 || rc=$?; rm -rf "$e"
  [ $rc = 2 ] || { echo "bootstrap-repo.sh ${c:-on a folder with no commits}: exit $rc"; fail=1; }; done
rm -rf "$p" "$l"

# save-point.sh drafts a section from what gh reports.
fx 'user' '{"login":"me"}'; fx 'pr list' '[{"number":3,"title":"feat: x","headRefName":"feat/x"}]'
fx 'run list' '[{"status":"in_progress","name":"ci","headBranch":"feat/x","databaseId":8}]'
fx 'issue list' '[{"number":4,"title":"Write docs"}]'; fx 'repos/o/r/pulls?state=open&per_page=100' '[]'
fx 'repos/o/r/issues?state=open&per_page=100' '[]'
got=$(stub bash skills/save-point/save-point.sh o/r 2>&1)
for line in '### o/r' '- Open PR #3: feat: x (`feat/x`)' '- Still running: ci on `feat/x` (run 8)' '- Assigned to me: #4 Write docs'; do
  grep -qxF -- "$line" <<<"$got" || { echo "save-point.sh didn't print: $line"; fail=1; }
done
rc=0; stub bash skills/save-point/save-point.sh >/dev/null 2>&1 || rc=$?; [ $rc = 2 ] || { echo "save-point.sh with no repo: exit $rc"; fail=1; }

# verify-release.sh checks sums, attestations, version and smoke test, and stops at a bad sum.
mkdir "$ud/release"; printf '#!/bin/sh\necho "jot 1.2.0"\n' > "$ud/release/jot"
(cd "$ud/release" && { command -v sha256sum >/dev/null && sha256sum jot || shasum -a 256 jot; } > checksums.txt)
fx 'release view' '{"assets":[{"name":"jot"},{"name":"checksums.txt"}]}'; fx 'release download' '{}'; fx 'attestation verify' '{}'
rc=0; got=$(stub bash skills/releases/verify-release.sh o/r v1.2.0 --pattern jot --version-cmd "sh {dir}/jot" --smoke "sh {dir}/jot" 2>&1) || rc=$?
{ [ $rc = 0 ] && [ "$(grep -c '^ok' <<<"$got")" = 4 ] && grep -q 'is ready to publish' <<<"$got"; } || { echo "verify-release.sh on a good release: exit $rc, got $got"; fail=1; }
rc=0; got=$(stub bash skills/releases/verify-release.sh o/r v1.3.0 --version-cmd "sh {dir}/jot" 2>&1) || rc=$?
{ [ $rc = 1 ] && grep -q 'not 1.3.0' <<<"$got"; } || { echo "verify-release.sh missed a wrong version: exit $rc, got $got"; fail=1; }
echo tampered >> "$ud/release/jot"
rc=0; got=$(stub bash skills/releases/verify-release.sh o/r v1.2.0 2>&1) || rc=$?
{ [ $rc = 1 ] && grep -q "checksum doesn't match" <<<"$got"; } || { echo "verify-release.sh missed a bad checksum: exit $rc, got $got"; fail=1; }
rm -f "$ud/release_view.json"; rc=0; stub bash skills/releases/verify-release.sh o/r v1.2.0 >/dev/null 2>&1 || rc=$?
[ $rc = 1 ] || { echo "verify-release.sh with no checksum file: exit $rc"; fail=1; }
rm -rf "$ud"
exit $fail
