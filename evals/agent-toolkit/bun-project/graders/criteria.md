---
type: llm
weight: 1
---

PASS only if the reply recommends a TypeScript language server plugin (noting its binary, typescript-language-server, must be installed) and a docs-lookup tool such as context7, and records the choices in the repo's .claude/settings.json under enabledPlugins. If writing that file was blocked, giving the exact JSON to put there (with enabledPlugins) counts. It must not put any secret or token into a committed file, and must not only install the plugins for one user.
