---
name: repo-setup
description: Use when creating a new GitHub repo, getting a repo ready to go public, or checking how an existing repo is set up, including community files, a license, branch protection or rulesets, DCO sign-off, Dependabot, pinned GitHub Actions, CI, issue and PR templates, CODEOWNERS, private vulnerability reporting or Discussions.
---

# Repo setup

A new GitHub repo starts with everything off: no ruleset, no private vulnerability reporting, nothing stopping a push straight to `main`. This skill gets a new repo to where you'd want it a year from now. For an existing repo, it audits it against the same list and fixes the gaps.

The reasons behind every item are in `knowledge/lessons.md` (Repo setup), at the plugin root two folders up from this file.

## The checklist

| Item | Who | How |
|---|---|---|
| README, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT | you | Copy from `templates/` and fill in every `{{PLACEHOLDER}}`. Keep any file the repo already has. |
| LICENSE | **owner** | It's a legal choice, so ask. Offer MIT (permissive), Apache-2.0 (permissive, with a patent grant) or GPL-3.0 (changes stay open). Then fetch the text: `gh api licenses/mit --jq .body > LICENSE`, and fill in the year and name. |
| Issue templates, PR template, CODEOWNERS | you | `templates/.github/`. |
| Dependabot, grouped and monthly | you | `templates/.github/dependabot.yml`. Add an entry for the project's own package manager too. |
| CI skeleton with a DCO check | you | `templates/.github/workflows/ci.yml`. Swap in the project's real test command. |
| Every Action pinned to a full commit SHA | you | Version in a comment: `uses: actions/checkout@<40-char sha> # v7.0.1`. Look up the SHA for a tag with `gh api repos/actions/checkout/commits/v7.0.1 --jq .sha`. |
| Ruleset: `main` is PR-only, required checks, branches don't have to be up to date | **owner** | It's a ruleset change, so ask first. Then `gh api repos/OWNER/REPO/rulesets --input <this skill's folder>/ruleset.json`. The check names in it must match the CI job names. |
| Private vulnerability reporting | you | `gh api -X PUT repos/OWNER/REPO/private-vulnerability-reporting` |
| Dependabot alerts | you | `gh api -X PUT repos/OWNER/REPO/vulnerability-alerts` |
| Sign-off required on web commits | you | `gh api -X PATCH repos/OWNER/REPO -F web_commit_signoff_required=true` |
| Discussions | you | `gh repo edit OWNER/REPO --enable-discussions` |

Files go in through a PR like any other change. If the ruleset is already on, that's the only way in anyway.

## Setting up

Work down the table. Do every "you" row. For each "owner" row, ask in one message: say what you'd pick and why in a line, and give the exact command you'll run once they say yes. Never choose a license for them, and never apply or change a ruleset without a yes.

Finish with a short report: one line per item saying what you did, and anything still waiting on the owner.

## Auditing

Run the audit script from the repo's root:

```sh
bash <this skill's folder>/audit.sh OWNER/REPO
```

It prints `ok`, `missing` or `unknown` for each item. Settings it can't reach (no `gh`, no network, no access) come back `unknown`. Report them as unchecked, never as fine, and give the command that would check each one. If you can't run the script, check the same items by reading the files, and say which settings you couldn't see.

Then list what's missing in the order the table gives it, with the fix for each. Offer to make the fixes. The "owner" rows still need a yes.

## Common mistakes

- **Requiring branches to be up to date before merging.** Every merge then restarts CI on every other open PR. `ruleset.json` leaves it off on purpose.
- **Pinning to a tag like `@v4`.** A tag can be moved to different code. Pin the SHA, and Dependabot will keep it current.
- **Weekly, ungrouped Dependabot.** It floods the PR queue. Monthly and grouped is plenty.
- **Ruleset check names that don't match a CI job.** The PR then waits forever for a check that never runs.
