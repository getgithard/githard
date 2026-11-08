---
name: contributors
description: Use when someone claims an issue, opens a pull request, or goes quiet on one, when deciding how to react to or thank a contributor, when two people's work collides, when writing an AI policy for contributors or a "writers wanted" issue, or when checking which outside PRs are still waiting on a reply.
---

# Contributors

People come back to a project that answers them. In the project these lessons come from, one first-time contributor waited two days for a reply because the watcher only reported new activity. This skill keeps every contributor answered, thanked and clear on what happens next.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Contributors, AI in the project). For the wording of any reply, use the `writing` skill.

## When something happens

| Event | What you do |
|---|---|
| Someone claims an issue | React 🚀, assign them, and reply with a welcome. On their first time, tell them that CI on a fork PR waits until a maintainer has read the diff and approved it, and that if `main` moves on they should click **Update branch**, because you won't push to their branch. |
| An outside PR opens | React 🚀 and reply the same day: thanks for the specific change, and when you'll review it. |
| You're reviewing it | React 👀. |
| It merges | React 🎉, thank them by `@handle` in the running release notes, and comment on the PR when the release ships. |
| They went beyond the ask | ❤️, plus a sentence saying what you noticed. |
| A PR has been quiet for 30 days | A person checks in, kindly, with a question that's easy to answer. |
| A PR has been quiet for 60 days | Close it with thanks, or finish it yourself and credit them in the commit and the release notes. |
| Two people's work collides | Say so, apologise for your side, and say which parts of theirs you'll keep. |

## Reactions

One reaction per item, and only on other people's posts. 🚀 for a claim or a new PR, 👀 while reviewing, 🎉 on merge, ❤️ for going beyond the ask, 👍 to acknowledge. Never 👎, 😄 or 😕. A reaction never stands in for a reply someone is owed.

## What's still owed

At the start of every session, before anything else, run:

```sh
bash ${CLAUDE_SKILL_DIR}/unanswered.sh OWNER/REPO
```

It lists outside PRs with no maintainer reply (`unanswered`), PRs quiet for 30 days (`check-in`) and PRs quiet for 60 days (`decide`). Exit 2 means it couldn't get an answer from GitHub. Report that as unknown, not as "nothing owed". If you can't run it at all, give the owner the exact command above and ask them to run it every session. A watcher that only shows new activity misses older PRs, and this check is what catches them.

## No stale bot

Don't add one, and if the repo has one (`actions/stale` in a workflow, or a `stale.yml`), suggest removing it. A bot closing a stranger's PR undoes the welcome. The 30- and 60-day rule above is done by a person.

## An AI policy

If the repo has no `AI_POLICY.md`, offer `${CLAUDE_SKILL_DIR}/templates/AI_POLICY.md`. Whether the project bans AI help is the owner's call, so ask. The template welcomes it with disclosure, and says the contributor is responsible for every line.

## "Writers wanted"

Writers are rarer on GitHub than developers, so a docs issue tagged `writers wanted` is worth having. Scope it like any starter issue: the page, the reader it's for, and "done when". Say plainly that the work is volunteer. Never hint at pay, bounties or a job that doesn't exist.

## An existing project

For a project that's already running, start with `unanswered.sh` and clear what's owed, oldest first. Then check for a stale bot, an `AI_POLICY.md`, and a CONTRIBUTING that covers claiming, sign-off, fork CI and quiet PRs. `repo-setup` has a CONTRIBUTING template that covers all four.
