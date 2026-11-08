---
type: regex
pattern: 'package-ecosystem: *"?npm'
match: contains
target:
  source: file
  path: .github/dependabot.yml
---
