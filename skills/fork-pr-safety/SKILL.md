---
name: fork-pr-safety
description: Use when a pull request comes from a fork, when its workflow runs show "approval required" or are waiting for a maintainer, when deciding whether to approve CI on a contributor's PR, when a fork PR's branch is out of date, when DCO fails on a contributor's commit or you're about to click Commit suggestion on one, or when checking whether a repo's workflows are safe for PRs from forks.
---

# Fork PR safety

Approving CI on a PR from a fork runs a stranger's code on your runners. Most of the time that's fine. What protects you is reading the diff first, every time, and approving only the commit you read.

The reasons behind each step are in `knowledge/lessons.md` (Fork PRs and CI safety), at the plugin root two folders up from this file.

## Before CI runs

1. **Get the full diff reviewed.** Dispatch the `fork-pr-reviewer` agent with the repo and the PR number, or with the diff file if that's what you have. It reads every line and returns a verdict. If you can't dispatch it, read `gh pr diff <N>` yourself, all of it, against the same list in `agents/fork-pr-reviewer.md` at the plugin root.
2. **Act on the verdict.**
   - `SAFE TO RUN CI`: approve the runs (step 3).
   - `OWNER MUST REVIEW`: anything under `.github/`, anything near secrets, or code that runs in CI goes to the owner. Give them the PR link and the findings, and don't approve until they say yes.
   - `DON'T RUN CI`: don't approve. Tell the owner what was found.
3. **Approve only the runs on the PR's current head commit:**
   ```sh
   bash <this skill's folder>/approve-runs.sh OWNER/REPO <N>
   ```
   If someone pushes after your review, the runs on the new commit still wait for a look.

## Never

- **Never push to a contributor's branch, and never click "Update branch" for them.** If branch protection is on, a push the author didn't make needs another approval, and the owner can't approve their own push, so the PR deadlocks. Ask the contributor to click **Update branch** instead.
- **Never use "Commit suggestion" in a repo that requires DCO.** The commit it makes has no sign-off, and DCO fails. Leave the suggestion as a comment and let the contributor commit it with `git commit -s`.
- **Never run a merge script on a fork PR** that might rebase or update its branch.

## When the contributor pushes again

A push dismisses approvals and puts CI back to waiting. Have the agent review the PR again, approve the runs on the new head, and re-approve the PR if it needs a review.

## DCO failures

If DCO fails on their commit, ask them to add the sign-off and force-push:

```sh
git commit --amend -s --no-edit && git push --force-with-lease
```

For more than one commit, they can use `git rebase --signoff main`. Don't fix it for them, because you'd be pushing to their branch.

## Checking an existing repo

For a repo that's already running, check two things and offer to fix both.

- **Who needs approval.** `gh api repos/OWNER/REPO/actions/permissions/fork-pr-contributor-approval`. GitHub's default, `first_time_contributors`, stops asking once someone has had a PR merged, so later PRs run without anyone reading the diff. Recommend `all_external_contributors`: `gh api -X PUT repos/OWNER/REPO/actions/permissions/fork-pr-contributor-approval -f approval_policy=all_external_contributors`.
- **`pull_request_target` workflows.** These run with the base repo's secrets and a write token. One that also checks out the PR's head code (`ref: ${{ github.event.pull_request.head.sha }}`, or the head ref) runs a stranger's code with your secrets. Flag every such workflow for the owner, and suggest moving it to `pull_request`.
