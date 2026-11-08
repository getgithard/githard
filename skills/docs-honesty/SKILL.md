---
name: docs-honesty
description: Use when writing or reviewing docs, a README, a docs site or install instructions, when checking docs against a release, after cutting a release, when docs mention features, flags or output that may not have shipped, or when hunting dead links, wrong version numbers or invented example output.
---

# Docs honesty

Docs that describe a feature you haven't shipped cost you twice: the reader loses an evening, and then they stop believing the rest. This skill keeps the docs true of what's released.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Docs and the website).

## The rules

- **Docs describe the released version.** A feature's docs merge when the feature is in a release. Until then they stay on the feature's branch, or under a heading that says "Coming in the next release".
- **Docs are code.** They live in the repo, change through PRs, and build in CI, so a broken page fails a check instead of a reader.
- **Real output only.** Every example of output comes from running the command against the released build. Never type it out by hand, and never write what it "would" print.
- **Install docs name the current release.** After each release, bump the version in every install line.

## Audit every release

After a release ships, dispatch the `docs-auditor` agent with the repo, the tag and the docs path. It compares the docs with the release's help text, notes and links, and reports each untrue claim as `path:line`. If you can't dispatch it, follow `${CLAUDE_PLUGIN_ROOT}/agents/docs-auditor.md` yourself.

For the two checks a script can do, links and flags:

```sh
bash ${CLAUDE_SKILL_DIR}/audit-docs.sh docs/ --tool jot --help-cmd "./dist/jot --help"
```

It prints `dead` for each link that answers 4xx or 5xx, `unknown` for one that doesn't answer, and `untrue` for each subcommand or `--flag` in a code block that the released help doesn't list. Run `--help-cmd` against the released build, not `main`. It exits 1 if anything is untrue.

Fix what the audit finds in one PR, with one line per fix in its description. Anything that would mean claiming an unreleased feature becomes an issue for the next release instead.

## A site that hides its 404s

If a docs site answers 200 for a page that doesn't exist, often because it serves its home page for every unknown path, dead internal links will pass any link check. Check with `curl -s -o /dev/null -w '%{http_code}' https://SITE/no-such-page`. Anything other than 404 needs a real 404 page.

## An existing project

Run the audit against the latest release first, and fix the oldest untrue claims first. Then add the docs build to CI, so the docs can't break without a failing check.
