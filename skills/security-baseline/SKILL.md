---
name: security-baseline
description: Use when improving a repo's security posture, or when a token, key or password may have leaked, including an OpenSSF Scorecard score or badge, the OpenSSF Best Practices badge, secret scanning and push protection, where secrets live, signed releases or build attestations, SECURITY.md, or installing an upstream tool that isn't signed.
---

# Security baseline

Security on a small project is mostly a dozen settings and habits that are easy to skip. This skill gets them done, measures them with OpenSSF Scorecard, and is honest about the checks no amount of settings can satisfy.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Security). Start with `repo-setup`: its ruleset, pinned Actions, Dependabot, SECURITY.md and private vulnerability reporting are most of a good score.

## Measure it

Copy `${CLAUDE_SKILL_DIR}/templates/.github/workflows/scorecard.yml` into the repo. It runs weekly and on every push to `main`, publishes the result, and lists findings under **Security**, then **Code scanning**. Once it has run:

```sh
bash ${CLAUDE_SKILL_DIR}/scorecard-check.sh OWNER/REPO
```

It lists every check below 10, lowest first. Each one is either `fixable` or `needs others`. Exit 2 means there's no published result yet.

## Be honest about what needs other people

Three checks can't be fixed with settings, and you never fake them:

- **Code-Review** wants changes approved by a second person. A solo maintainer's PRs score low until a second maintainer reviews. Approving your own PRs with a second account is faking it.
- **Contributors** wants contributors from several organizations. That comes from real outside contributions over time.
- **Maintained** wants 90 days of activity. A new repo simply has to wait.

Say this plainly in the report, and don't call a score "perfect" while any of them is below 10.

## The rest

| Item | Who | How |
|---|---|---|
| Secret scanning and push protection | you | `gh api -X PATCH repos/OWNER/REPO --input -` with `{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}` |
| Workflow tokens read-only by default | you | `permissions: read-all` or `contents: read` at the top of every workflow, widened per job only where needed |
| Signed releases | you | Build attestations in the release workflow. See `releases`. |
| OpenSSF Best Practices badge | **owner** | Sign in at https://www.bestpractices.dev with GitHub, then **Get Your Badge Now**. You can prepare an answer for every question from what the repo already has, but the owner submits it. |
| Badges in the README | you | Scorecard: `https://api.securityscorecards.dev/projects/github.com/OWNER/REPO/badge`. Best Practices: the URL bestpractices.dev gives after sign-up. |

## Secrets

Secrets live only in GitHub secrets: **Settings**, then **Secrets and variables**, then **Actions**. They never go in chat, commit messages, logs, issue text, state files or docs. Not even as an example, and not even partly masked. If one leaks, rotate it first, then clean up. Removing it from history doesn't un-leak it.

## Unsigned upstreams

When the project installs a tool whose publisher doesn't sign it, don't copy their `curl | sh`. Download the exact file, check it against a pinned sha256 in your own script, and install it by path. In the README, say what's unsigned and what vouches for it, which is the pinned checksum.

## An existing repo

Add the Scorecard workflow first, and let it run. Fix the `fixable` checks lowest score first, through PRs. Report the `needs others` checks as they are.
