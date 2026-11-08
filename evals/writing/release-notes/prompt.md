---
tags: [writing]
max_turns: 6
allowed_tools: [Read, Glob, Grep, Skill]
---

Write the GitHub release notes for v0.4.0 of my small CLI, `stash` (a homelab backup tool). Here's what happened since v0.3.0:

- #41 merged, by me (@stash-maintainer): restores now resume after a dropped connection.
- #44 merged, by @rkhan: `stash list` is 10x faster on buckets with 50,000+ objects (6 s down to 0.6 s).
- #45 merged, by @mlopez: fixed a crash when a folder name contains a space.
- #47 open, by @tbaker: Backblaze B2 support. It's approved and I'll merge it tomorrow.
- #48 merged, by me: bumped dependencies.
