---
type: regex
pattern: 'npm test|node --test|npm run test'
match: contains
target:
  source: file
  path: .github/workflows/ci.yml
---
