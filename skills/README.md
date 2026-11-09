# Skills

Each skill has its own folder here, `skills/<name>/SKILL.md`, plus any reference files it needs.

Built so far:

- [`using-githard`](using-githard/SKILL.md): the front door. It works out which skill fits your request, and tells you plainly when that skill isn't built yet.
- [`writing`](writing/SKILL.md): anything people will read, such as READMEs, docs, release notes and replies to contributors. It uses your project's own style guide if you have one, and GitHard's voice if you don't.
- [`repo-setup`](repo-setup/SKILL.md): gets a new repo ready to go public, or audits an existing one. It ships the community files, templates, CI and ruleset, plus `audit.sh`, which tells you what's missing.
- [`contributors`](contributors/SKILL.md): claims, replies, reactions, quiet PRs, thanks, an AI policy and "writers wanted" issues. `unanswered.sh` lists the outside PRs still waiting on you.
- [`fork-pr-safety`](fork-pr-safety/SKILL.md): reviews a fork PR before its CI runs, and approves only the runs on the commit that was read. It uses the [`fork-pr-reviewer`](../agents/fork-pr-reviewer.md) agent and `approve-runs.sh`.
- [`issues-and-roadmap`](issues-and-roadmap/SKILL.md): milestones, a sized project board, sub-issues and blocked-by links, and starter issues a stranger can finish. `issue-health.sh` flags issues nobody could pick up, and counts the pool.
- [`merging`](merging/SKILL.md): merges when the ruleset's required checks pass on the head commit, reruns only download flakes, and runs PRs one at a time. Ships `merge-when-green.sh` and `merge-queue.sh`.
- [`releases`](releases/SKILL.md): running release notes, cutting only after the last fix, a draft-only release workflow with checksums and build attestations, `verify-release.sh` before publishing, and the list for after it ships.
- [`docs-honesty`](docs-honesty/SKILL.md): docs that only describe the release, with real output. The [`docs-auditor`](../agents/docs-auditor.md) agent and `audit-docs.sh` find dead links and commands or flags the released help doesn't list.
- [`org-setup`](org-setup/SKILL.md): the org's profile README and `.github` repo, a verified domain, pins and member defaults, with every setting handed to the owner. `org-audit.sh` checks an org, and `bootstrap-dotgithub.sh` is the one command the owner runs.
- [`security-baseline`](security-baseline/SKILL.md): OpenSSF Scorecard measured weekly, honest about the checks only other people can satisfy, secret scanning, secrets handling, and unsigned upstreams. `scorecard-check.sh` lists what's fixable.
- [`growth`](growth/SKILL.md): your own surfaces first, Show and tell only where it's alive, never spam on strangers' repos, giving back within each project's AI policy (`ai-policy-check.sh`), and measuring every channel (`traffic.sh`).

The rest of the planned skills, their order and what "done" means for each are in [`docs/design.md`](../docs/design.md) and [`docs/plan.md`](../docs/plan.md).
