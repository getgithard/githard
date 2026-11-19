#!/usr/bin/env bash
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
printf '%s\n' "$*" >> "$GH_FIXTURES/calls"
s=""; if [ "$1" = api ]; then shift; [ "$1" = -X ] && shift 2; [ "$1" = --paginate ] && shift; [ "$1" = --slurp ] && { s=1; shift; }; key=$1; else key="$1 $2"; fi
f=$GH_FIXTURES/$(printf '%s' "$key" | tr -c 'A-Za-z0-9' _).json; [ -f "$f" ] || exit 1
q=.; while [ $# -gt 0 ]; do [ "$1" = --jq ] && q=$2; shift; done
if [ -n "$s" ]; then jq -s . "$f"; else jq -r "$q" "$f"; fi
GH
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
printf '#!/bin/sh\ncat "$GH_FIXTURES/scorecard.json"\n' > "$ud/bin/curl"; chmod +x "$ud/bin/curl"
printf '{"score":7.3,"date":"2026-11-01","repo":{"commit":"abcdef1234"},"checks":[]}' > "$ud/scorecard.json"
for c in ":0" "--min 7:0" "--min 7.5:1" "--min ten:2"; do
  read -ra a <<<"${c%:*}"; rc=0; stub bash skills/security-baseline/scorecard-check.sh o/r ${a[@]+"${a[@]}"} >/dev/null 2>&1 || rc=$?
  [ $rc = "${c##*:}" ] || { echo "scorecard-check.sh ${c%:*} on 7.3: exit $rc, wanted ${c##*:}"; fail=1; }
done
# issue-health.sh counts a writers-wanted issue toward the pool
fx 'issue list' '[{"number":3,"title":"Write the sync page","body":"Done when: it ships","milestone":{"title":"M1"},"issueType":{"name":"Task"},"assignees":[],"labels":[{"name":"writers wanted"}]}]'
stub bash skills/issues-and-roadmap/issue-health.sh o/r 1 2>&1 | grep -qx 'pool     1 ready to pick up, target 1' ||
  { echo "issue-health.sh didn't count a writers-wanted issue in the pool"; fail=1; }
rm -rf "$ud"
exit $fail
