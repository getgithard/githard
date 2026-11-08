---
type: regex
pattern: 'uses: *[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40}'
match: contains
target:
  source: file
  path: .github/workflows/ci.yml
---
