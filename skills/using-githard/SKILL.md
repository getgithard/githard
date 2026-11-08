---
name: using-githard
description: Use when someone asks what GitHard can do, or asks for help setting up or running a GitHub org or repo, including community files, rulesets, issues, roadmaps, contributors, fork PRs, merging, releases, docs, security, growth or session handoffs, and it isn't yet clear which GitHard skill fits.
---

# Using GitHard

GitHard helps you set up and run a GitHub org and its repos the way well-run projects do. This skill is the front door: find the skill that fits the request, and be straight about the ones that aren't built yet.

## Pick the skill

Match the request to a row. If a row says **built**, load that skill and follow it.

If it says **planned**, your final answer opens with this sentence, word for word apart from the skill's name. Put it there even if you already said it while working:

> GitHard's `<skill>` skill isn't built yet, so this is general advice rather than GitHard's own checklist.

It comes first even when something else is wrong, such as a missing repo or an empty folder. Then help as well as you can. Never invent the skill's steps, scripts or commands.

| The request sounds like | Skill | Status |
|---|---|---|
| "What can GitHard do?", or anything that doesn't fit below | `using-githard` (this one) | built |
| Writing a README, docs, release notes, a reply or a post in the house voice, or using a project's own style guide | `writing` | built |
| Setting up a new repo, or auditing an existing one: community files, license, ruleset, DCO, Dependabot, pinned Actions, CI, labels, templates | `repo-setup` | built |
| Milestones, a project board, starter issues, a pool of scoped work, "writers wanted", issue types, sub-issues, blocked-by | `issues-and-roadmap` | built |
| Welcoming a claim, thanking contributors, a quiet PR, an AI policy for contributors, PRs still waiting on a reply | `contributors` | built |
| A PR from a fork: reading it before CI runs, approving runs, DCO trouble, whether workflows are safe for forks | `fork-pr-safety` | built |
| Merging when CI is green, a queue of PRs, flaky checks, the API limit | `merging` | planned |
| Cutting, verifying or publishing a release, and what comes after | `releases` | planned |
| Checking the docs only say what shipped, a docs audit per release | `docs-honesty` | planned |
| OpenSSF Scorecard or Best Practices, secrets, signed releases, SECURITY.md | `security-baseline` | planned |
| A new org: profile README, the `.github` repo, verified domain, pinned repos | `org-setup` | planned |
| Getting the project seen: directories, starter repos, Show and tell, giving back | `growth` | planned |
| A handoff file, remembering decisions, resuming where the last session stopped | `save-point` | planned |

A request can span rows. Take them in the order the work happens: org, then repo, then issues, then people, then shipping.

## How GitHard works with you

These hold in every skill. The reasons behind each one are in `knowledge/lessons.md` at the plugin root, two folders up from this file.

- **Act, then report.** Ask first only about money, account or ruleset changes, legal questions, disputes with people, and deletions you can't undo.
- **Make every ask copy-paste ready.** An exact command with absolute paths, or numbered steps with the URL and the button names.
- **Never claim what isn't shipped.** Not in a README, not in docs, and not about GitHard itself.
- **Be careful with other people's code.** Read a fork PR's full diff before its CI runs, never push to a contributor's branch, and send `.github/` changes to the owner.
- **Be kind and quick with people.** Every outside PR gets a reply.
- **Follow the project's own rules first:** its style guide, AI policy, license and contribution terms. Where it has none, use GitHard's voice in `knowledge/voice.md`.
- **Small, serial, verified.** One merge at a time, an eye on the API limit, and evidence before you say something's done.

## What GitHard won't do

Push to someone else's branch, pass off its own approval as a human review, post promotional issues on strangers' repos, contribute where a project's AI policy bans AI help, or decide money, legal or people questions for the owner.
