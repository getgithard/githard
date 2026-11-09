---
name: save-point
description: Use when stopping work partway, at the end of a session, when starting a new session on a project already under way, when asked to write or read a handoff file, to remember a decision for next time, or to resume where a previous session left off.
---

# Save point

A session that ends without a save point leaves the next one guessing: which PR was half-merged, who's waiting on a reply, what was decided and why. This skill keeps one running file the next session can trust.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (The working agreement between the owner and the agent).

## The handoff file

One file in the repo, usually `docs/handoff.md`, committed like any other change. Add a new section, newest last, at every natural stopping point: a merged PR, a question waiting on the owner, or the end of the session. Never rewrite old sections. They're the history.

Draft the facts with:

```sh
bash ${CLAUDE_SKILL_DIR}/save-point.sh OWNER/REPO [OWNER/REPO...]
```

It prints a dated section with your open PRs, workflows still running, outside PRs owed a reply, and issues assigned to you, read from GitHub so they can't drift. Fill in the three lines it leaves for you:

- **Done:** what merged or shipped, with PR numbers.
- **Next:** the very next step, specific enough to start without asking.
- **Gotchas:** anything learned today the next session would trip over. A flag that's needed, a tool that misbehaves, a check that lies.

Also list what's owed to whom: replies, reviews, and anything waiting on the owner, with the exact steps you gave them.

## Decisions that should outlast the session

A preference or rule the owner states ("always squash", "never touch the site on Fridays") goes where the next session reads it first: the project's agent instructions file (such as `CLAUDE.md` or `AGENTS.md`), or the agent's memory if the project doesn't keep one. Write the rule and the reason. A decision that only lives in chat is lost the moment the session ends.

## Starting a session

1. Read the agent instructions file, then the **last** section of the handoff file.
2. Check what's owed before anything else: `bash ${CLAUDE_PLUGIN_ROOT}/skills/contributors/unanswered.sh OWNER/REPO`.
3. Check for anything left running: `gh run list --limit 10` and `gh pr list --author @me`.
4. Then pick up **Next**.

If the last section and GitHub disagree (it says a PR is open, but it's merged), GitHub wins. Say so in the first new section.

## Background jobs

Before stopping, list every job still running (merge loops, renders, watchers) in the handoff, with how to check on each. Stop the ones the next session won't need. Never leave several polling loops running against the API.

## An existing project

If there's no handoff file, start one: a first section that records what's open (run `save-point.sh`), and the decisions you can find in the README, CONTRIBUTING and recent PRs, each marked as inferred until the owner confirms it.
