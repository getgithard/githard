---
name: merging
description: Use when merging pull requests once CI is green, merging several PRs in a row, waiting on required checks, when CI fails with what looks like a flaky download or network error, when hitting the GitHub API rate limit while polling, or when deciding whether a ruleset should require branches to be up to date.
---

# Merging

Merging by hand means sitting and watching checks. Merging with a careless script means merging something that isn't green, or burning through the API limit until every tool you have goes blind. This skill merges one PR at a time, on the commit that passed, and stops on anything that isn't a flake.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Merging).

## One PR

```sh
bash ${CLAUDE_SKILL_DIR}/merge-when-green.sh OWNER/REPO <PR> [--method squash] [--timeout-min 60]
```

- It reads the required checks from the base branch's ruleset, so nothing's hard-coded. A hard-coded list makes PRs in other repos wait out the full timeout for a check that never runs.
- It merges with `--match-head-commit`, so a push that lands after the checks pass can't slip in.
- If a required check fails, it reads the failed job's log. When every failure looks like a download flake (a 5xx, a timeout, a reset, DNS), it reruns only the failed jobs, at most twice. Anything else is a real failure: it stops and says which check.
- An empty or failed answer from GitHub means "unknown, ask again", never "done".

Exit 0 means merged. Exit 1 means a real failure or a timeout. Exit 2 means it refused (a fork PR) or couldn't read the PR or the ruleset.

## Several PRs

```sh
bash ${CLAUDE_SKILL_DIR}/merge-queue.sh OWNER/REPO 41 42 43
```

One runner, one PR at a time, in the order you give. Never start several merge loops at once. GitHub allows 5,000 API requests an hour, shared by every tool on your token, and parallel pollers use it up together. Both scripts wait when fewer than 200 requests are left.

## Never

- **Never run a merge script on a PR from a fork.** The script refuses. Review it with `fork-pr-safety`, then merge it by hand.
- **Never edit a script while it's running.** Bash reads a script as it runs, so the edit corrupts the run. Both scripts copy themselves to a temp file before they start, so editing the originals is safe.
- **Never require branches to be up to date in the ruleset.** Each merge would restart CI on every other open PR. `repo-setup`'s ruleset leaves it off.

## An existing repo

Check the ruleset first: `gh api repos/OWNER/REPO/rules/branches/main`. If `strict_required_status_checks_policy` is `true`, branches must be up to date. Suggest turning that off, and ask first, because it's a ruleset change. If there are no required checks at all, the script merges once nothing is failing. Say so, and suggest adding them with `repo-setup`.
