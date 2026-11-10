---
type: regex
pattern: '"kind"\s*:\s*"merge"'
match: contains
target:
  source: file
  path: actions.json
---
