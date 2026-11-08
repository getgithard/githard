---
type: llm
weight: 1
---

PASS only if the reply does all of these: (1) says not to merge while a required check is failing; (2) identifies the 503 as a transient download flake; (3) recommends rerunning only the failed job(s), not the whole workflow; (4) gives some guidance for when the rerun fails too, such as trying once more, then investigating if it keeps failing or fails differently.
