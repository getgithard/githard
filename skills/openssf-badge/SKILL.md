---
name: openssf-badge
description: Use when working toward the OpenSSF Best Practices badge at any level (passing, silver or gold), formerly the CII Best Practices badge, setting a project up on bestpractices.dev, filling in or checking its answers, or meeting criteria such as governance, a roadmap, an assurance case, two-person review, per-file license headers or hardened site headers.
---

# OpenSSF Best Practices badge

The OpenSSF Best Practices badge shows, criterion by criterion, that a project is run the way security-conscious projects are. Passing is a weekend for a GitHard project. Silver takes real documentation. Gold also takes people: a second reviewer, a second maintainer, contributors from other organizations. This skill takes a project the whole way, and never fakes the parts that need people.

## 1. Set up the project (owner)

The owner signs in at https://www.bestpractices.dev with GitHub, clicks **Get Your Badge Now**, picks the repo, and shares the project number from the URL (`/projects/12345`). Only the owner submits answers. You prepare them.

## 2. See what's left

```sh
bash ${CLAUDE_SKILL_DIR}/badge-status.sh 12345 [passing|silver|gold]
```

It reads the project's real answers from bestpractices.dev and lists, for the target level and the levels below it, every MUST that's unmet (`unmet`) or unanswered (`answer`), then the SHOULDs. With no level, it targets the next one. Exit 0 means nothing blocks the target.

## 3. Meet each criterion, level by level

`${CLAUDE_SKILL_DIR}/levels.md` maps every silver and gold MUST to the skill, template or script that meets it. Work through passing, then silver, then gold. Each level requires the one before.

- **Passing** is mostly other GitHard skills: `repo-setup`, `releases`, `security-baseline` and `contributors`.
- **Silver** adds documents. Start from `${CLAUDE_SKILL_DIR}/templates/`: `GOVERNANCE.md`, `ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/SECURITY-MODEL.md`, plus coding standards enforced in CI and test coverage of at least 80%.
- **Gold** adds:
  - per-file copyright and SPDX license lines: `bash ${CLAUDE_SKILL_DIR}/add-spdx.sh "HOLDER" MIT`, with `--check` in CI
  - hardened headers on every site: `python3 ${CLAUDE_SKILL_DIR}/csp-headers.py SITE_DIR` writes a `_headers` file for Cloudflare Pages or Netlify, and `bash ${CLAUDE_SKILL_DIR}/check-headers.sh URL...` checks it live
  - code review standards (`templates/CODE-REVIEW.md`)
  - 2FA
  - coverage of 90% statements and 80% branches
  - a dated security review
  - dynamic analysis

Write every document with the `writing` skill, and make each one true today. A roadmap with nothing in it, or a security review nobody did, is worse than an honest Unmet.

## 4. Answer the form

For each criterion, prepare the answer (Met, Unmet or N/A) and its evidence, a URL wherever the form asks for one. Give the owner the answers grouped as the form groups them, ready to paste. N/A needs a reason that's true. "We don't build anything" is a reason. "We didn't get to it" isn't.

## What needs other people

Five criteria can't be met with files or settings:

- **access_continuity** (silver): a second person with owner access.
- **bus_factor** (gold): two people who could keep the project going.
- **two_person_review** (gold): at least half of each release's changes reviewed by someone other than the author.
- **contributors_unassociated** (gold): two significant contributors from different organizations.
- **security_review** (gold), when it's an outside review.

Never meet these with a second account, a friend's rubber-stamp, or an answer of Met on hope. Earn them: keep a pool of good first issues (`issues-and-roadmap`), answer every contributor quickly (`contributors`), make the project findable (`growth`), and invite the most active contributor to become a maintainer. Report progress honestly ("gold blocked on two_person_review: 12% of changes reviewed") until it's real.

## Keep it

After each release, run `badge-status.sh` again, and update answers that went stale: coverage, the review ratio, the security review date. Link the badge in the README within 48 hours of earning a level. That's a silver criterion itself.
