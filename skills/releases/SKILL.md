---
name: releases
description: Use when preparing, cutting, verifying or publishing a release, writing or keeping release notes or a changelog as changes merge, adding checksums, signing or build attestations to release assets, tagging a Claude Code plugin version, or working through what has to happen after a release ships.
---

# Releases

A release is a promise: these files, built from this commit, do what the notes say. This skill keeps the notes honest as you go, builds a draft nobody has to trust blind, and checks it before anyone publishes.

The reasons behind each step are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Releases). Write the notes with the `writing` skill.

## Notes as you go

Keep the next release's notes in a draft GitHub release, and add an entry each time a change merges, not the night before:

```sh
gh release view v1.3.0 --json body --jq .body > notes.md   # or start an empty file the first time
# add one line: what changed for the reader, and "thanks @handle" next to an outside contributor's change
gh release edit v1.3.0 --notes-file notes.md || gh release create v1.3.0 --draft --title v1.3.0 --notes-file notes.md
```

Only merged, shipped changes go in. "Almost done" waits for the next release.

## Cut only after the last fix

Before you cut, both of these come back empty:

```sh
gh issue list --milestone "v1.3.0" --state open
gh pr list --search "milestone:v1.3.0" --state open
```

If either doesn't, the release waits, or the open items move to the next milestone with the owner's yes.

## Build a draft

Copy `${CLAUDE_SKILL_DIR}/templates/.github/workflows/release.yml` into the repo and replace its build step with the real build. It only runs when someone starts it (**Actions**, then **Release**, then **Run workflow**). It builds into `dist/`, writes `SHA256SUMS`, attests build provenance for every file, and creates a **draft** release that keeps the running notes. It never publishes.

## Check it before anyone publishes

```sh
bash ${CLAUDE_SKILL_DIR}/verify-release.sh OWNER/REPO v1.3.0 \
  --version-cmd '{dir}/mytool --version' --smoke '{dir}/mytool selftest'
```

It downloads the assets (`--pattern '*linux*'` for some of them), checks each against `SHA256SUMS` or `*checksums.txt`, checks each has a build attestation from that repo, then runs the version command and the smoke test, where `{dir}` is the download folder. Any failure stops it. Publish only after it passes: `gh release edit v1.3.0 --draft=false`.

The version and smoke commands run the downloaded build on your machine. Use them only on your own project's release.

## A Claude Code plugin

A plugin's release is a tag: `claude plugin tag --dry-run`, then `claude plugin tag --push`. It tags `{name}--v{version}` and checks that `plugin.json` and the marketplace entry agree. Run the plugin's evals before you tag.

## After it ships

Work through the list and report each item as done or not done:

1. Comment on every merged PR in the release that it shipped, and thank outside contributors by handle.
2. Update the README in every repo that names the version or install steps, and bump version pins in install docs.
3. Regenerate generated docs from the release tag, not from `main`.
4. Upgrade your own installed copy, so you're not testing against bugs that are already fixed.
5. Open issues for the work the release creates: testers wanted, docs gaps, writers wanted.
6. Start the next draft release, so the next merge has somewhere to go.

## An existing project

Look at the last release first: `gh release view --json assets,body`. Is there a checksum file? Do `gh attestation verify` checks pass? Do the notes say what changed for a reader, and credit contributors? Offer the release workflow and a running draft for next time. Don't rewrite past releases without the owner's yes.
