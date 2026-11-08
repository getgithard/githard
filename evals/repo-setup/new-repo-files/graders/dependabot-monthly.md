---
type: regex
pattern: 'interval: *"?weekly|interval: *"?daily'
match: not_contains
target:
  source: file
  path: .github/dependabot.yml
---
