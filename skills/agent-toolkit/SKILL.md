---
name: agent-toolkit
description: Use when starting work on a project and deciding which Claude Code plugins, skills, MCP servers or language servers (LSPs) it needs, when setting up a repo so every contributor's Claude Code gets the same tools, when a language server is missing, or when someone asks whether a plugin or MCP server is safe to install.
---

# Agent toolkit

An agent with the right tools writes less, guesses less and breaks less. A language server tells it about a type error before the build does. A docs lookup stops it inventing an API that changed last month. This skill picks the tools a project needs and records them in the repo, so everyone who works on it gets the same set.

## Pick

```sh
bash ${CLAUDE_SKILL_DIR}/toolkit.sh [DIR]
```

It looks at the repo's files and prints one line per plugin, with the reason:

- **Language servers** for each language it finds, from Anthropic's official marketplace. A language server needs its binary installed. The script says whether it is, and gives the install command if not.
- **superpowers** for planning, test-driven work and debugging, and **ponytail** for keeping changes small, on any project with code.
- **context7** for current library docs, on any project with dependencies.
- **githard** for running the repo, on any GitHub project.
- **frontend-design** and **playwright** when there's a web UI.

A project that doesn't have code yet has nothing to detect. Ask what it'll be written in, or read its plan, and add the language servers by hand.

## Where tools may come from

Plugins and MCP servers run code on the user's machine, so only recommend them from two places:

1. Anthropic's official marketplace (`claude-plugins-official`).
2. GitHard's vetted list, `${CLAUDE_SKILL_DIR}/vetted.tsv`, which says who publishes each one and what it runs.

Anything else needs the owner's explicit yes. Say who publishes it, what it runs (skills only, hooks, an MCP server, a binary), and where its source is, and wait for the answer. `toolkit.sh --apply` refuses anything not in `vetted.tsv`.

## Record it in the repo

If the user asked you to set the tools up, that's the yes for everything on the vetted list: apply them, then report what you added and why. If they only asked what to use, show the picks and offer to apply them. Either way, anything off the list waits for its own yes.

```sh
bash ${CLAUDE_SKILL_DIR}/toolkit.sh [DIR] --apply
```

It merges them into `.claude/settings.json`: `enabledPlugins`, plus `extraKnownMarketplaces` for any marketplace that isn't the official one. It keeps whatever's already there. Commit the file through a PR. Everyone who clones the repo and trusts it gets the same plugins offered.

An MCP server that isn't packaged as a plugin goes in `.mcp.json` at the repo root, under the same rules about where it comes from. Never put a token in either file. Reference an environment variable instead (`"Authorization": "Bearer ${API_TOKEN}"`) and say where the value comes from.

Language server binaries aren't in the repo, so list their install commands in CONTRIBUTING's setup section.

## Before you start building

Check the toolkit before the first line of code, not after. A language server that's missing turns every type error into a failed build. Run `toolkit.sh` again whenever the project adds a language or a web UI.
