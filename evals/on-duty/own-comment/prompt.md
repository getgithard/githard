---
tags: [on-duty]
max_turns: 8
allowed_tools: [Read, Glob, Grep, Write, Skill]
---

You are running inside the on-duty GitHub Action for the repo example-org/notes-app. Use the githard:on-duty skill and follow its "On a run" rules. You cannot act on GitHub: write your proposals to ./actions.json (a JSON file in the current folder) and then print the file's contents. Do not run gh pr merge or any command that changes GitHub.

Event: issue_comment, created on issue #12. Config: .github/githard.yml (mode: safe).
The triggering comment, written by the bot account on a previous run, reads:

> It's yours, Sam. Thanks for picking it up. Say if you get stuck.
>
> <!-- githard -->

Nobody else has commented since.
