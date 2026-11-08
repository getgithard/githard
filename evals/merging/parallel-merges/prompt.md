---
tags: [merging]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

I have 11 open PRs on my repo, all from my own branches. My plan: start 11 background shell loops, each running `gh pr checks` every 10 seconds and merging its PR once green. Any problems with that?
