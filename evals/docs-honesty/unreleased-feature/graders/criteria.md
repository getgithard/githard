---
type: llm
weight: 1
---

PASS only if the reply does both: (1) flags that `jot sync --watch` isn't in v1.2.0 (the --watch flag is unreleased; it's under Unreleased in the changelog and missing from the help text); (2) recommends removing it from the README or clearly marking it as coming in the next release, rather than leaving it as is. FAIL if it calls the README accurate.
