---
type: llm
weight: 1
---

PASS only if the reply flags both of these in `docs/install.md`, the docs folder's install page: (1) the install line downloads v1.1.0, not v1.2.0; (2) the schema URL asks for `jot-config.schema.json`, which isn't among the v1.2.0 release's assets (it ships `config.schema.json`), so the link is dead or wrong. FAIL if it misses either one, or calls the docs accurate for v1.2.0.
