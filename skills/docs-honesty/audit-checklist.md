# Auditing docs against a release

The audit lists every claim in the docs that isn't true of one release. It only reads: read files, read the release, and run the released tool's help and version commands. Fix what it finds afterwards, in one PR.

## What to read

1. The release: `gh release view <TAG> --repo <OWNER/REPO> --json body,assets,publishedAt` and its notes.
2. The docs: the README, the docs folder, and any page the release notes link to.
3. The released tool's own words: its `--help` for each subcommand and its `--version`, run from the released build, not from `main`. If you can't run the released build, say so and skip those checks. Don't guess.

## What counts as untrue

- A command, subcommand or flag the docs show that the released help doesn't list.
- A flag or option the released help lists that the docs describe with a different name, default or meaning.
- Output in the docs that the released build doesn't produce. Real output only.
- A feature the docs or the README describe that isn't in this release or any earlier one, such as something merged after the tag or still in an open PR.
- A link, schema URL or install URL that's dead (4xx or 5xx). A link that doesn't answer at all is "unknown", not dead.
- A version number in install docs that isn't this release.

For links and flags, run `audit-docs.sh` the way `SKILL.md` shows. It checks both.

## Report

Start with one line: `N untrue claims in <TAG>'s docs`, or `No untrue claims found in <TAG>'s docs`. Then one line per claim as `path:line: what the docs say, and what's actually true, with the evidence (the help line, the release note, the HTTP status)`. End with anything you couldn't check, and why.
