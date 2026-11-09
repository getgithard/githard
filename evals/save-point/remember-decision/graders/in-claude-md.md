---
type: regex
pattern: 'squash[\s\S]*friday|friday[\s\S]*squash'
flags: i
match: contains
target:
  source: file
  path: CLAUDE.md
---
