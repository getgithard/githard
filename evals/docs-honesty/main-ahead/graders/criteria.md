---
type: llm
weight: 1
---

PASS only if the reply flags that the README documents `jot sync --watch`, and that `--watch` isn't in v1.2.0: it was added on main after the v1.2.0 tag, so the README describes main, not the release. It should recommend removing that line from the README for now, or marking it as coming in the next release. FAIL if it calls the README accurate for v1.2.0, or checks it only against the code on main.
