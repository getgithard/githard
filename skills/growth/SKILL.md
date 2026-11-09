---
name: growth
description: Use when trying to get a project seen, used or starred, planning a launch or announcement, posting about it in other communities or Show and tell, making a starter or template repo, contributing back to projects it depends on, or measuring where visitors and contributors come from.
---

# Growth

People find a project through the things it owns: its README, its org page, its releases, its starter repo. Spam gets a project ignored, and sometimes banned. This skill grows the project through its own surfaces, gives back honestly, and measures what works.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Growth and outreach, AI in the project).

## Your own surfaces first

Work through these before posting anywhere else. Write every word with the `writing` skill, and claim only what's released.

- **The repo's front:** a description, a homepage URL, and topics (`gh repo edit OWNER/REPO --description "..." --homepage https://... --add-topic cli --add-topic notes`), a social preview image (the owner uploads it under **Settings**), and a README whose first two lines say what it does for the reader.
- **The org page:** use `org-setup`.
- **A starter repo** people can copy: a minimal working example, marked as a template with `gh repo edit OWNER/REPO --template`.
- **Help-wanted issues:** a pool of scoped issues from `issues-and-roadmap`. They're how readers become contributors.
- **Release posts** with real output, and short demos recorded from the released build.

## Posting elsewhere

- **Never open "try our tool" issues or PRs on strangers' repos.** It's spam, whatever the wording.
- **Show and tell, only where it's alive.** Post in a project's Discussions Show and tell category only if people posted there recently. Check first, and follow that project's rules. One post, with real output, never a repost.
- **The owner posts launch announcements** (forums, newsletters, social media) under their own name. Draft them with `writing` and hand them over.

## Giving back

Contribute to projects you depend on in small, reviewed pieces, and only within each project's rules on AI help:

```sh
bash ${CLAUDE_SKILL_DIR}/ai-policy-check.sh OWNER/REPO
```

It prints every line in the usual policy files that mentions AI. Read them. If the project bans AI help, don't contribute, and say so if asked. "No policy found" only means those files say nothing. Check the project's docs site too, and ask in an issue or discussion before sending AI-assisted work.

## Measure every channel

```sh
bash ${CLAUDE_SKILL_DIR}/traffic.sh OWNER/REPO snapshots.tsv
```

It shows the last 14 days of views and referrers, and stars. GitHub only keeps 14 days, so with a file argument it appends a dated snapshot. Take one before a launch and one a week after. A channel that brought nobody isn't worth repeating, however good it felt to post there.

## An existing project

Start with the repo's front and the starter repo, the cheapest wins. Then run `traffic.sh` weekly for a month to find which channels actually bring people, and put the time there.
