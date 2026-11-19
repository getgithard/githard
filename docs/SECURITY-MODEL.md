# Security model

## What you can expect

- GitHard acts only through your own Claude Code session and your own `gh` login. It has no server, collects nothing, and sends nothing anywhere except to GitHub (and, when you ask, to bestpractices.dev or Cloudflare) through the tools you've already signed in to.
- It never reads, prints or stores a secret's value. Scripts that touch secrets, such as keyparity's or `security-baseline`'s, work with names only.
- It asks before money, legal questions, account or ruleset changes, disputes with people, and deletions that can't be undone.
- It does **not** protect you from a malicious plugin you install yourself, or from a compromised GitHub account.

## Threat model

| Threat | Boundary (see [ARCHITECTURE.md](ARCHITECTURE.md)) | How it's handled |
|---|---|---|
| A fork PR runs malicious code in CI | other people's code | `fork-pr-safety`: read the full diff before approving any run, approve only the head commit, flag `.github/` and `pull_request_target` changes |
| Instructions hidden in issue text or a web page | content GitHard reads | Skills treat fetched content as data. Actions come only from the user |
| A secret leaks into a repo or a log | the user's GitHub | secret scanning with push protection (`repo-setup`, `security-baseline`). Secrets only in GitHub secrets. Rotate first if one leaks |
| A tampered or unverified release | downloaded assets | `releases`: SHA256SUMS and build attestations, checked by `verify-release.sh` before publishing |
| An Action tag moved to malicious code | the project's CI | Every Action is pinned to a full commit SHA, and Dependabot updates the pins |
| A malicious plugin or MCP server | plugins it recommends | `agent-toolkit` recommends only from the official marketplace and a vetted list |

## Secure design principles

- **Least privilege:** workflow tokens are read-only by default, and write permissions are granted per job. The fork PR review and the docs audit only read.
- **Fail safe:** scripts report `unknown` when GitHub doesn't answer, never `ok`. The merge script treats an empty answer as "ask again", never as "done".
- **Complete mediation:** every merge waits for the required checks on the exact head commit (`--match-head-commit`).
- **Input validation:** scripts take arguments as lists, never as shell strings built from input, and match names against allowlist patterns.
- **Open design:** everything is public, including the evals that show what each skill does.

## Common weaknesses we counter

- **Command injection** (CWE-78): `gh` and `git` run with argument lists, and workflow inputs go through environment variables, not `${{ }}` inside shell scripts.
- **Exposure of secrets** (CWE-200, CWE-532): no values are ever requested, and push protection is on.
- **Untrusted code execution in CI** (CWE-829): fork PR approval for every outside contributor, and no `pull_request_target` with a checked-out head.
- **Supply chain** (CWE-494): SHA-pinned Actions, attested releases, pinned sha256 for unsigned upstream tools.

## Security reviews

| Date | Who | Scope | Result |
|---|---|---|---|
| 19 November 2026 | self-review: James Conway, with Claude Code | every script under `skills/`, every workflow, against the threat model and the boundaries above | 4 fixed, 3 accepted, below |

Gold asks for a review within the last five years that covers the requirements and boundaries above. This one is a self-review. An outside review comes later.

### 19 November 2026

We read every script and workflow, looking for text that crosses a boundary and ends up as code, for writes outside the folder a script was given, and for downloads that run before they're checked.

**Fixed:**
- `fill-templates.sh` put `--project`, `--repo`, `--owner` and `--contact` straight into a `sed` replacement. A `&`, `#` or `\` broke the edit, and a crafted `--contact` could use sed's `w` flag to write a file. The values are now escaped, and `check.sh` covers it (CWE-78).
- `release.yml` deleted any release on the tag before making the draft. A re-run after publishing would have replaced the published release with a draft. Now it only ever replaces a draft.
- `audit-docs.sh` checks URLs from docs that anyone can edit in a PR. Redirects are now limited to http and https.
- `ai-policy-check.sh` printed lines from another project's files as they were, terminal escape sequences included. Control characters are now stripped, and `check.sh` covers it.

The private copies that `merge-when-green.sh`, `merge-queue.sh` and `add-spdx.sh` run from now delete themselves when they exit.

**Accepted:**
- `verify-release.sh --version-cmd` and `--smoke`, and `audit-docs.sh --help-cmd`, run a command the maintainer types. That's what they're for. `verify-release.sh` runs them only after the checksums and attestations pass.
- Lines fetched from GitHub, such as issue titles and other projects' policies, reach Claude's context. The skills treat them as data, and the actions come only from the user (see the threat model above).
- The CI `coverage` job runs as root inside the pinned `kcov/kcov` image. It has a read-only token and no secrets, and outside PRs wait for approval before any job runs.
