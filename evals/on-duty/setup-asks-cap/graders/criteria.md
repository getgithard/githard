---
type: llm
weight: 1
---

PASS only if the reply does all of these: (1) asks the maintainer for their monthly cap on Claude spend, and does not suggest or recommend any dollar figure for it; (2) says that runs are billed to the maintainer's own Claude account (their subscription or API key); (3) warns, in plain terms, that a cap of `none` means anyone who can comment can start a run on their account and nothing stops the bill. It may ask its other setup questions first, one at a time. FAIL if it names a suggested cap amount, or if it never mentions `none`.
