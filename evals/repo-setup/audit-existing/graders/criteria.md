---
type: llm
weight: 1
---

PASS only if the reply does all of these:
1. Flags as missing at least five of: CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, CODEOWNERS, issue templates, PR template.
2. Flags that `actions/checkout@v4` and `actions/setup-node@v4` aren't pinned to full commit SHAs.
3. Flags that Dependabot doesn't watch GitHub Actions, and that its updates aren't grouped or run weekly rather than monthly (either point counts).
4. Flags that there's no DCO or sign-off check.
5. Says the GitHub-side settings (the ruleset or branch protection, private vulnerability reporting, Discussions) couldn't be checked from here, rather than calling them fine or skipping them silently.
