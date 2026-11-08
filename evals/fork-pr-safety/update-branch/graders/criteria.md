---
type: llm
weight: 1
---

PASS only if the reply does both: (1) advises against the maintainer updating or pushing to the contributor's branch themselves; (2) explains that the maintainer's push would need a fresh approval the maintainer can't give for their own push, or that it causes a deadlock or dismisses approval, and recommends asking the contributor to click Update branch. FAIL if it says clicking it themselves is fine.
