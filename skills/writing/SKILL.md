---
name: writing
description: Use when writing or rewriting anything a person will read for a GitHub project, such as a README, docs, release notes, a changelog, an issue or PR description, a reply to a contributor, or a launch post, or when copy reads as stiff, corporate or AI-sounding.
---

# Writing

What people read decides whether they trust the project. This skill sets the voice for all of it.

## First, find the project's own style

Look before you write. A project's own guide always wins over GitHard's.

- `STYLE.md`, `STYLEGUIDE.md`, `docs/style*.md`, `.github/STYLE*.md`
- A style or writing section in `CONTRIBUTING.md`
- A prose linter's config: `.vale.ini`, `.markdownlint*`, `.textlintrc*`

If you find one, follow it, even where it disagrees with GitHard's voice. Then say in one line which guide you used, for example: "Written to `docs/style-guide.md`." If you find none, use GitHard's voice in `${CLAUDE_PLUGIN_ROOT}/knowledge/voice.md`. Read it before you write. Don't work from memory of it.

## By kind of text

| You're writing | What matters most |
|---|---|
| README | What it does for the reader, in the first two lines. An install line only if there's a release to install. |
| Docs and guides | Plain technical writing: what it is, the exact command, real output. Keep it conversational, but cut the selling. |
| Release notes | Only what merged and shipped in this release. Thank each outside contributor by `@handle` next to their change. |
| Issue or PR text | What's wrong or what changes, why, and "done when". A stranger should be able to pick it up. |
| Reply to a contributor | Their name, thanks for the specific thing, and the next step with a date or a condition. On a first PR from a fork, also tell them that CI waits until a maintainer has read the diff and approved it, and that if `main` moves on they should click **Update branch**, because you won't push to their branch. |
| Post or announcement | The reader's problem first, then what changed. Real output or a real figure beats any adjective. |

The reasons behind the release-notes and reply rules are in `knowledge/lessons.md` (Releases, Contributors).

## Before you hand it over

- Every claim is true of what's released today. Something planned is either left out or called planned.
- None of the banned words in `voice.md` appear, and nothing is built as "It's not just X, it's Y".
- Read it aloud in your head. Any sentence you wouldn't say to someone across a table gets rewritten.

`${CLAUDE_SKILL_DIR}/examples.md` has before and after pairs for each kind of text.
