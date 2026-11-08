# GitHard: design

Status, 8 Nov 2026: M1 is built (`using-githard`, `writing`, `repo-setup`, and the eval harness). The rest is planned, and `docs/plan.md` gives the order it gets built in.

## What it is

GitHard is a Claude Code plugin. It helps someone build and run a GitHub org and its repos the way well-run projects do, whether they're starting one or already have one: how the repos are set up, the issues, contributors, reviews, merges, releases, docs, security and growth. It's built from what actually worked, and what went wrong, running a real open-source project from its first commit (`knowledge/lessons.md`).

## Who it's for first

**Solo builders and small teams starting from zero:** one person, or a few, with an idea and a GitHub account and no maintainer experience. They want to look and work like a mature project from day one, without learning every GitHub setting the hard way.

**Existing orgs and repos** too. If a project is already running, GitHard audits it against the same lists and brings it up to the same standard, one fix at a time, so nobody has to start over.

## What it does for them

You tell GitHard what you're making. It sets up the org and repo the way you'd want them in a year, explains each choice in one line, and asks you only for the things it can't do: a DNS record, a payment, a setting with no API. Then it keeps running the project with you: triaging issues, welcoming contributors, reviewing fork PRs safely, merging, releasing, keeping the docs honest, and keeping a save point so any session can pick up where the last one stopped.

## Principles

These carry through every skill. Each comes from `knowledge/lessons.md`.

1. **Act, then report.** Ask only for money, account or ruleset changes, legal questions, disputes with people, and deletions that can't be undone. Every request to the human is copy-paste ready.
2. **Never claim what isn't shipped.** Docs, READMEs and posts describe the released version, and real output beats invented output.
3. **Safe with other people's code.** Read the full diff before running a fork's CI, never push to a contributor's branch, and send `.github/` changes to the owner.
4. **Kind and quick with people.** Every outside PR gets a reply, every claim a welcome, every merged contribution thanks by name.
5. **The house voice** (`knowledge/voice.md`) for every word a reader sees, unless the project has its own style guide.
6. **Respect the project's own rules:** its AI policy, its license, its contribution terms, and those of every upstream it touches.
7. **Small, serial and verified.** One merge at a time, an eye on the API limit, and evidence before saying something is done.

## Shape of the plugin

```
.claude-plugin/plugin.json        manifest
.claude-plugin/marketplace.json   this repo is its own marketplace
skills/<name>/SKILL.md            one folder per skill, with reference files beside it
agents/<name>.md                  subagents the skills hand work to
knowledge/lessons.md              shared field notes the skills draw on
knowledge/voice.md                the default house voice
evals/                            eval cases per skill (claude plugin eval)
```

Skills reference `knowledge/` instead of copying it, so a lesson is fixed in one place.

### Planned skills

Names are working names. Each skill's description has to say when to use it, in the words a user would say.

| Skill | What it covers |
|---|---|
| `using-githard` | The entry point: what GitHard can do, and which skill fits the request. Loads the principles. |
| `org-setup` | A new org: profile README, the public `.github` repo with default community files, verified domain, pinned repos, member and security defaults. |
| `repo-setup` | A new or existing repo: community files, license choice, ruleset, DCO, Dependabot, pinned Actions, CI skeleton, private vulnerability reporting, labels, templates, Discussions. Audits an existing repo against the same list. |
| `issues-and-roadmap` | Milestones, a project board, starter issues with "done when" criteria, issue metadata, keeping a pool of scoped work, "writers wanted" issues. |
| `contributors` | Welcoming claims, the reaction rules, the quiet-PR policy, thanks in release notes, answering every outside PR, the unanswered-PR check, AI policy for contributors. |
| `fork-pr-safety` | Reviewing a fork PR before its CI runs, approving runs on the head commit only, what never to do to a contributor's branch, DCO pitfalls. |
| `merging` | The merge-when-green script that reads required checks from the ruleset, serial merges, flake reruns, API-limit care. Ships the scripts. |
| `releases` | Running release-notes draft, the cut, verifying artifacts (checksum, attestation, smoke test), publishing, and the post-release checklist across every repo. |
| `docs-honesty` | Docs as code, the shipped-claims test, the per-release docs audit, real output only. |
| `security-baseline` | OpenSSF Scorecard and Best Practices, secrets handling, signed releases and attestations, SECURITY.md, supply-chain notes for unsigned upstreams. |
| `writing` | The house voice applied to READMEs, docs, release notes, replies and posts, and how to swap in a project's own style. |
| `growth` | Org profile, directories, starter repos, Show and tell etiquette, no spam, giving back to dependencies within their AI policies, measuring what each channel brings. |
| `save-point` | The handoff file, memory of decisions, background watchers, and how a new session resumes. |

### Planned agents

| Agent | Job |
|---|---|
| `fork-pr-reviewer` | Read-only review of a fork PR's full diff for anything that runs code with secrets, touches `.github/`, or doesn't match its description. Reports, never approves. |
| `docs-auditor` | Compares docs against a release: CLI help, schemas, release notes, links. Reports each claim that isn't true of the release. |

### Hooks

None planned for the first release. Revisit once the skills exist. A candidate is a reminder to run the unanswered-PR check at session start.

## What GitHard won't do

- Push to someone else's branch, approve its own work as if it were a human review, or fake the checks that need other people (a second reviewer, unaffiliated contributors).
- Post promotional issues on strangers' repos.
- Contribute to a project whose AI policy bans AI help.
- Decide money, legal or people questions for the owner.

## How we'll know it works

- **Evals:** each skill ships with cases in `evals/` that run with `claude plugin eval` and pass against a no-plugin baseline.
- **Proof:** the owner builds a few new products with GitHard from an empty org, and each one ends up with a perfect repo-setup audit, a passing OpenSSF Best Practices badge, and a release made with the releases skill.
- **Launch:** before the new year, listed in its own marketplace (`/plugin install githard --marketplace jamesconwaydev/githard`), with a README that shows a real before and after.
