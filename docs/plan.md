# GitHard: build plan

Each phase is a GitHub milestone, and each item below is an issue in it. Build in order: later skills lean on earlier ones. A skill is done when its `SKILL.md` and reference files are written, its evals pass against a no-plugin baseline, `claude plugin validate .` passes, and its PR is merged.

## M0: Foundation (done 8 Nov 2026)

The plugin skeleton, the manifests, this plan, `docs/design.md`, `knowledge/`, repo community files, CI that validates the plugin, labels, templates, Discussions, milestones and these issues.

## M1: Core (done 8 Nov 2026)

1. **`using-githard`:** the entry skill and its routing table. Done when a request for each planned skill reaches the right one in evals, including skills that don't exist yet, where it says so plainly.
2. **`writing`:** the house voice as a skill, with before and after examples, and swapping in a project's own style guide.
3. **`repo-setup`:** new-repo setup and an audit mode for existing repos. Ships the community-file templates. Done when, on a scratch repo, it produces every file on its checklist and the audit flags each missing item.
4. **Eval harness:** `evals/` layout, a first case per M1 skill, and a CI job that runs what can run without secrets.

## M2: People

5. **`contributors`**
6. **`fork-pr-safety`**, with the `fork-pr-reviewer` agent
7. **`issues-and-roadmap`**

## M3: Shipping

8. **`merging`**, shipping the merge-when-green and serial-merge scripts
9. **`releases`**
10. **`docs-honesty`**, with the `docs-auditor` agent

## M4: Org and growth

11. **`org-setup`**
12. **`security-baseline`**
13. **`growth`**
14. **`save-point`**

## M5: Proof and launch

15. **Dogfood:** set up a brand-new product org and repo with GitHard alone, and log every place it fell short as an issue.
16. **README with a real before and after**, install line, and screenshots of a real result.
17. **First release:** tag `githard--v0.1.0` with `claude plugin tag`, and test the marketplace install from a clean machine.
18. **Launch** before the new year.

## Rules for building

- Read `CLAUDE.md` first in every session.
- One skill per PR. Keep the skill text in the house voice, and short enough that its token cost (`claude plugin details`) stays reasonable.
- A lesson lives in `knowledge/lessons.md`. A skill cites it rather than repeating it at length.
- Keep the example project generic. Never name any real project GitHard's lessons came from.
