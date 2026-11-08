# Handoff

Newest section last. Each session adds one at its stopping points.

## 2026-11-08 ~20:30 UTC: foundation laid

Done: plugin skeleton (`.claude-plugin/`), `docs/design.md`, `docs/plan.md`, `knowledge/lessons.md`, `knowledge/voice.md`, community files, issue and PR templates, Dependabot, CI (`scripts/check.sh`), labels, milestones M0 to M5, one issue per plan item, Discussions on.

Next: issue #1 in M1 (`using-githard`). Nothing else is in progress.

Open questions for James: none.

## 2026-11-08 ~20:30 UTC: using-githard merged

Done: #1 (`using-githard`) merged in #19, with four eval cases. With the plugin, 12 of 12 runs pass. The no-plugin baseline passes 0 of 12. Removed `agents/README.md`, because Claude Code loaded it as an agent with no frontmatter.

Gotchas:
- Run evals with `--judge-model sonnet`. The haiku judge failed a reply that met every point.
- Eval criteria must ask for something only the plugin knows, or a baseline that says "GitHard isn't installed" passes.
- Eval traces in `/private/tmp/e-*` are deleted after the run. Pass `--keep-temp` to keep them.

Next: #2 (`writing`).

Open questions for James: the plugin has no icon. The directory wants a square PNG at `.claude-plugin/icon.png`, 512 to 2048 px.

## 2026-11-08 ~20:45 UTC: M1 done

Done: #2 `writing` (#21), #3 `repo-setup` (#22), and #4, the eval CI checks (this PR). All of M1 is built. The full suite, run with `--runs 3 --scaffold --allow-tools Bash Write Edit --judge-model sonnet`, passes every case with the plugin.

Gotchas:
- `claude plugin eval --case` keeps only the last glob. Filter by skill with `--tag <skill>`. Every case's `prompt.md` has `tags: [<skill>]`.
- On three writing cases (style guide, rewrite, release notes), Claude without the plugin already passes. They're regression guards. Only `first-pr-reply` shows the skill making a difference.
- An eval with a scaffold needs `--scaffold`. One that writes files or runs Bash needs `--allow-tools Bash Write Edit`.

Waiting on James (repo settings, so they need his yes): `bash skills/repo-setup/audit.sh jamesconwaydev/githard` reports this repo has no CODEOWNERS, no DCO check in CI, Dependabot alerts off and web-commit sign-off off. The plugin icon is still open too.

Next: M2, starting with #5 (`contributors`).

## 2026-11-08 ~21:00 UTC: audit gaps closed

James's standing rule: fix every gap and bug found along the way, don't just report it. GitHard is for new and existing orgs and repos alike, and `docs/design.md` now says so.

Done: Dependabot alerts and web-commit sign-off are on (both API calls). This PR adds CODEOWNERS and a `dco` CI job. Once it merges, `dco` gets added to the `protect-main` ruleset as a required check.

Note: `CLAUDE.md` is in James's global git ignore, so it isn't in the repo. Changes to it only apply on his machine.

Next: #5 (`contributors`). The icon is still waiting on James.
