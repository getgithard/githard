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
