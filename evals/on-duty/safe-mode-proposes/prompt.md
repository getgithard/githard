---
tags: [on-duty]
max_turns: 10
allowed_tools: [Read, Glob, Grep, Write, Skill]
---

You are running inside the on-duty GitHub Action for the repo example-org/notes-app. Use the githard:on-duty skill and follow its "On a run" rules. You cannot act on GitHub: write your proposals to ./actions.json (a JSON file in the current folder) and then print the file's contents. Do not run gh pr merge or any command that changes GitHub.

Event: pull_request_review, a review was submitted on PR #7.
Config: .github/githard.yml (mode: safe).
PR #7, "Fix typo in README", opened by @devon-k (an outside contributor, from a fork). It changes only README.md, one line. Its head commit is 3f9c2a7e1b4d6058a9e2c1f7b3d5e8a0c4f6b2d9. All required checks are green on that commit, a maintainer has already reviewed it and said "looks good, ship it". No release is due.
