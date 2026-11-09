# Architecture

GitHard is a Claude Code plugin. There's no server and no build: it's Markdown instructions, small shell and Python scripts, and eval cases.

## What it's made of

- **`.claude-plugin/`:** the plugin manifest (`plugin.json`) and its marketplace entry (`marketplace.json`).
- **`skills/<name>/SKILL.md`:** one skill per job, such as `repo-setup`, `merging` or `releases`. Claude Code loads a skill when a request matches its description. A skill can ship scripts (`*.sh`, `*.py`) and templates beside it, and refers to them through `${CLAUDE_SKILL_DIR}`.
- **`agents/`:** subagents a skill hands work to: `fork-pr-reviewer` and `docs-auditor`. Both are read-only.
- **`knowledge/`:** `lessons.md` holds the field notes every skill is built from, and `voice.md` the house voice. Skills point to them through `${CLAUDE_PLUGIN_ROOT}` instead of copying them.
- **`evals/<skill>/<case>/`:** eval cases (`prompt.md`, graders, sometimes a `scaffold.sh` that builds a throwaway repo) run with `claude plugin eval`.
- **`scripts/check.sh`:** the checks CI runs without credentials.

## How a request flows

1. A user asks Claude Code for something in their own words.
2. Claude Code matches it against the skills' descriptions and loads one. `using-githard` takes anything that doesn't clearly fit.
3. The skill tells Claude what to do, and when to stop and ask the owner.
4. Claude runs the skill's scripts or `gh` commands against the user's GitHub, with the user's own credentials and permission settings.

## Trust boundaries

- **The user's GitHub account and token.** Every change GitHard makes goes through `gh`, as the user. GitHard never stores, prints or moves a credential.
- **Other people's code.** Fork PRs and their diffs are untrusted input. `fork-pr-safety` reads them before any CI runs, and the `fork-pr-reviewer` agent can only read.
- **Content GitHard reads** (issue text, READMEs, web pages, API responses) is data, never instructions.
- **Plugins and MCP servers it recommends** run code on the user's machine. `agent-toolkit` only recommends from Anthropic's official marketplace and a vetted list, and asks before anything else.
- **Downloaded release assets** are checked against checksums and attestations before anything runs them (`verify-release.sh`).
