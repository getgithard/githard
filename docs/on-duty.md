# On duty: GitHard running a repo while the maintainer sleeps

Status: draft, 10 Nov 2026. Working name `on-duty`.

## Why

A project feels alive when every claim, PR and question gets a good answer on the same day. Most maintainers can't keep that up. They sleep, they have jobs, they go on holiday. Today GitHard only works while someone has a Claude Code session open, so a claim on keyparity#18 waited a day for a reply.

`on-duty` keeps a repo looked after around the clock. From outside it should look as though the maintainer never sleeps: people get answered, PRs get reviewed and merged, issues get triaged, and releases ship on time. The work should be just as careful whether the bot or the human does it.

Some maintainers want it fully on its own. Others want a human to approve before anything leaves the building. Both are first-class.

## Goals

- Look after a repo 24/7 with no Claude Code session open, in two modes:
  - **Full auto:** it acts alone, merges and releases included.
  - **Safe mode:** it does the work, but every action that goes out to the world waits for a human's final approval. That covers merges, releases and npm publishes, closing PRs or issues, approving fork CI runs, and settings changes.
- In safe mode, chat has its own setting:
  - `auto`: replies to people go out on their own.
  - `approve`: every reply waits for approval.
  - `approve-first: N`: the first N replies wait, then chat switches to `auto` on its own. The maintainer can watch how it talks before trusting it.
- Act as either identity, the maintainer's choice:
  - **The maintainer's own account.** It uses their token, so replies show as them.
  - **A second account turned into the project's bot.** It's a normal GitHub user the maintainer creates and gives access to.
- Do everything inside GitHub. The workflows run in GitHub Actions, approvals happen in GitHub, and there's no server, app or dashboard to install.
- Let the maintainer set every option. Risky options print a plain warning when they're turned on.
- Let the maintainer plug in outside review tools (CodeQL, Scorecard, a Claude or third-party security review, anything that reports a check). The bot waits for those checks before it merges.
- Reuse the existing skills for every judgment: `contributors`, `fork-pr-safety`, `merging`, `releases`, `issues-and-roadmap`, `docs-honesty`, `writing`. `on-duty` is the part that keeps running, plus the approval gate. It doesn't add a second set of rules.

## Non-goals

- **No coding.** It doesn't fix bugs, build features or open its own code PRs for issues. A separate coding bot for solo developers comes later, as its own project.
- No hosted service, GitHub App or web UI.
- No notifications outside GitHub. GitHub's own notifications and phone app are the channel.

## Anti-goals (failure even if it "works")

- A contributor gets a reply that's wrong, cold, or obviously canned. "No difference from a human" is the bar.
- A malicious PR gets merged, or a fork's code runs with the project's secrets.
- A safe-mode user finds that something went out without their yes.
- It burns money in a loop, for example by answering its own comments.
- It breaks GitHard's existing promises: it pushes to a contributor's branch, fakes a human review, or ignores the project's AI policy.

## Constraints

- Runs on GitHub Actions, using `anthropics/claude-code-action` (pinned to a full SHA, as with every Action here), with the GitHard plugin installed through its `plugin_marketplaces` and `plugins` inputs.
- **Every project brings its own Claude account.** The maintainer adds their own `ANTHROPIC_API_KEY`, or a `CLAUDE_CODE_OAUTH_TOKEN` from their own subscription, as a secret in their own repo. GitHard has no server, no shared key and no account of its own. Nothing ever runs on GitHard's or its author's Claude account, and setup never offers one. If the secret is missing, the workflows do nothing except say so.
- Costs stay low: short, bounded runs.
- Everything in `docs/SECURITY-MODEL.md` still holds: SHA pins, least-privilege tokens, no `pull_request_target` with a checked-out head, and fork CI approved only on the head commit.
- **Issue and PR text is untrusted input, and here it reaches a model holding a write token.** Hard rules can't be left to the model's judgment. These have to be enforced by scripts:
  - who may approve;
  - which paths count as risky;
  - whether required checks passed on the exact head commit;
  - whether the bot is replying to itself.
- The project's own `AI_POLICY.md` decides whether replies say they came from a bot. GitHard sets no disclosure rule of its own. If there's no policy, the setup step asks the maintainer.

## How it works (decided so far)

**Workflows in the repo.** Setup adds workflow files to the repo:
- an event workflow that wakes on new issues, issue comments, PRs and reviews;
- a scheduled run, so quiet PRs, the 30- and 60-day check-ins, release timing and pending approvals get picked up even when nothing new happens.

Each run does one small, bounded job and exits.

**Identity.** The maintainer gives a token as a repo secret, either their own fine-grained PAT or the bot account's. That token acts in GitHub. The default `GITHUB_TOKEN` stays read-only. The bot ignores events made by its own identity, except approvals from the maintainer when it runs as their account. The builder needs to work out how to tell those apart when the bot and the maintainer share one account.

**The approval queue (safe mode).** A pinned issue titled "Waiting for you" holds one comment per pending action. Each comment has the action, a one-line why, a link, and for a reply the full draft text. The maintainer approves by replying, or with a reaction from the GitHub phone app. They can also edit a draft before approving it. A script checks that the approver has the right association (`OWNER`, or listed maintainers) and that the target hasn't changed since the card was written: same head SHA, PR still open. Only then does the action go through. A card whose target changed is withdrawn and rewritten.

**Risky changes.** A PR that touches `.github/`, build or release scripts, or dependency manifests and lockfiles always waits for a human by default, even in full auto. The maintainer can turn that off, and the setup step warns plainly what that means.

**Outside reviewers.** Config lists check names (for example `CodeQL`, `Scorecard`, a security-review job). Merges wait for all of them on the head commit, on top of the ruleset's required checks.

**Reviews and rulesets.** The bot never posts an APPROVE review. Under the maintainer identity, that would be a faked human review. It merges only where the ruleset allows a merge without one. keyparity's `protect-main` needs 0 approvals and has no bypass actors, so full auto works there unchanged. On a repo whose ruleset requires an approving review, merges always go to "Waiting for you". Setup says so, and never edits the ruleset itself.

**Tokens per identity.** For the maintainer identity, use a fine-grained PAT. For the bot identity on an org-owned repo, use a fine-grained PAT from the bot account, which must be an org member with write access. keyparity is org-owned. A bot account on a personal repo would need a classic PAT, which breaks least privilege. So in v1 the bot identity is for org-owned repos only, and setup explains why.

**Releases.** on-duty uses the `releases` skill as it is. It keeps the running notes, and starts the project's own release workflow, which builds a **draft** and never publishes. It runs `verify-release.sh` on the draft. It never holds registry credentials: npm and other registry publishing stays with the project's existing release workflow and that workflow's secrets. The version comes from the Conventional Commits since the last tag (`fix` gives a patch, `feat` a minor). A breaking change always goes to a human. A release is proposed once unreleased user-facing changes have sat for `release_after_days` (default 7). In safe mode, "publish" is a card. In full auto, it flips the GitHub draft to published only after `verify-release.sh` passes.

**Spending cap.** Every run is billed to the maintainer's own Claude account, and anyone who can comment can start one. So the maintainer sets their own monthly cap, at any amount they choose. GitHard picks no number. Setup asks for one. `none` is allowed, with a plain warning that strangers' comments then cost money with no ceiling. When the cap is hit, the bot stops working, posts a card to "Waiting for you", and starts again next month or when the maintainer raises the cap. The builder settles how spend is counted (for example from the Action's execution output) and where the running total lives, and handles a subscription token, where there's no per-run price. A per-person limit for first-time posters is a config option too, set by the maintainer.

**Config.** One file in the repo, so changing it is a reviewed PR like any other change:

```yaml
# .github/githard.yml (shape only; the builder settles names)
mode: safe                # auto | safe
chat: approve-first: 5    # auto | approve | approve-first: N  (safe mode only)
identity: bot             # maintainer | bot
risky_paths_need_human: true
wait_for_checks: [CodeQL, Scorecard]
monthly_cap_usd: 25       # the maintainer's own number, or none
first_timer_runs_per_day: 3   # optional, the maintainer's own number
release_after_days: 7
```

## Left to the builder

- The skill and file layout. Probably a new `on-duty` skill that installs and audits the workflows and config, plus a workflow template.
- Exact triggers, the cron interval, and how each run picks its one job.
- How approvals are parsed, and how "the bot's own event" is detected under each identity.
- Which actions count as risky in full auto beyond the default paths above.
- Evals: there must be cases for the approval gate, ignoring its own comments, a prompt-injection attempt in an issue, and a risky-path PR in full auto.
- Where this sits in `docs/plan.md`, and its issue.

## My calls (not yet confirmed by James)

- Working name `on-duty`.
- Config in `.github/githard.yml`, so changes go through review.
- **Always queued, even in full auto:** ruleset and account changes, money, legal questions, disputes between people, and deletions that can't be undone. This matches GitHard's existing rule. Full auto covers project care, not the owner's decisions.
- `risky_paths_need_human` defaults to on.
- Safe mode is the default for a new setup.
- First dogfood on keyparity, but only if James chooses to add a Claude secret there himself. Otherwise the dogfood uses a test repo whose owner brings their own account.
- No APPROVE reviews from the bot. Repos that require a review keep merges with a human.
- The bot identity is for org-owned repos only in v1, because personal repos would need a classic PAT.
- on-duty never holds registry tokens. Versions come from Conventional Commits, a breaking change always goes to a human, and `release_after_days` defaults to 7.
