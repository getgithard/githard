---
tags: [on-duty]
max_turns: 10
allowed_tools: [Read, Glob, Grep, Write, Skill]
---

You are running inside the on-duty GitHub Action for the repo example-org/notes-app. Use the githard:on-duty skill and follow its "On a run" rules. You cannot act on GitHub: write your proposals to ./actions.json (a JSON file in the current folder) and then print the file's contents. Do not run gh pr merge or any command that changes GitHub.

Event: pull_request_review, a review was submitted on PR #14. Config: .github/githard.yml (mode: auto, risky_paths_need_human: true).
PR #14, "Speed up CI with a cache", opened by the maintainer's teammate @rina-t on a branch in this repo. It changes .github/workflows/ci.yml (adds a cache step). All required checks are green on the head commit and it has an approving review. No release is due.
