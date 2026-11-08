---
name: issues-and-roadmap
description: Use when planning work on a GitHub repo, such as milestones, a roadmap, a project board or sizes, when writing an issue someone else should be able to pick up, including good first issues and "writers wanted", when setting issue types, sub-issues or blocked-by links, or when checking whether a repo's issues are ready for contributors.
---

# Issues and roadmap

An issue a stranger can finish is the cheapest contributor you'll ever get. One that just says "improve search" sits there until you do it yourself. This skill keeps the roadmap visible and every issue ready to pick up.

The reasons behind each rule are in `${CLAUDE_PLUGIN_ROOT}/knowledge/lessons.md` (Issues and the roadmap).

## The roadmap

- **Milestones are phases,** each with a one-line goal in its description. Close one when its last issue closes.
- **A project board** for the org, with `Status` and a `Size` field (XS, S, M, L). `gh project create --owner ORG --title "Roadmap"`, then `gh project field-create <N> --owner ORG --name Size --data-type SINGLE_SELECT --single-select-options XS,S,M,L`.
- **A big issue is a parent with sub-issues.** Link a sub-issue with `gh api -X POST repos/OWNER/REPO/issues/<PARENT>/sub_issues -F sub_issue_id=<CHILD'S id>`, where the id comes from `gh api repos/OWNER/REPO/issues/<N> --jq .id`, not from the issue number.
- **Say what blocks what:** `gh api -X POST repos/OWNER/REPO/issues/<N>/dependencies/blocked_by -F issue_id=<BLOCKER'S id>`.

## Every issue

Each one gets a type (`gh issue edit <N> --type Bug|Feature|Task`), a milestone, a card on the board with a size, and a "Done when" list. Every PR that closes one says `Fixes #N`, so the issue links to its PR.

## Issues for newcomers

Start from `${CLAUDE_SKILL_DIR}/templates/starter-issue.md`. A starter issue names the files to change, says how to test, gives "Done when", and says which files to stay out of. Label it `good first issue` or `help wanted`.

For docs, use a `writers wanted` label. Writers are rarer on GitHub than developers. Say plainly that the work is volunteer, and never hint at pay.

## Keep a pool

Aim for about ten scoped, unassigned issues at any time, so nobody who turns up has to wait for work. When you reach one nobody's claimed, take it yourself and scope a new one.

## Checking a repo

```sh
bash ${CLAUDE_SKILL_DIR}/issue-health.sh OWNER/REPO [POOL_TARGET]
```

It lists each open issue that's missing a type, a milestone or "Done when", then counts the pool. Exit 1 means there's work to do. Exit 2 means GitHub didn't answer: report that as unknown, not as healthy. For an existing project, run it first, fix the oldest issues first, then build the pool up to target.
