# Handoff

Newest section last. Each session adds one at its stopping points.

## 2026-11-08 ~20:30 UTC: foundation laid

Done: plugin skeleton (`.claude-plugin/`), `docs/design.md`, `docs/plan.md`, `knowledge/lessons.md`, `knowledge/voice.md`, community files, issue and PR templates, Dependabot, CI (`scripts/check.sh`), labels, milestones M0 to M5, one issue per plan item, Discussions on.

Next: issue #1 in M1 (`using-githard`). Nothing else is in progress.

Open questions for James: none.

## 2026-11-08 ~20:30 UTC: using-githard merged

Done: #1 (`using-githard`) merged in #19, with four eval cases. With the plugin, 12 of 12 runs pass. The no-plugin baseline passes 0 of 12. Removed `agents/README.md`, because Claude Code loaded it as an agent with no frontmatter.

Gotchas:
- Run evals with `--judge-model sonnet`. The haiku judge failed a reply that met every point.
- Eval criteria must ask for something only the plugin knows, or a baseline that says "GitHard isn't installed" passes.
- Eval traces in `/private/tmp/e-*` are deleted after the run. Pass `--keep-temp` to keep them.

Next: #2 (`writing`).

Open questions for James: the plugin has no icon. The directory wants a square PNG at `.claude-plugin/icon.png`, 512 to 2048 px.

## 2026-11-08 ~20:45 UTC: M1 done

Done: #2 `writing` (#21), #3 `repo-setup` (#22), and #4, the eval CI checks (this PR). All of M1 is built. The full suite, run with `--runs 3 --scaffold --allow-tools Bash Write Edit --judge-model sonnet`, passes every case with the plugin.

Gotchas:
- `claude plugin eval --case` keeps only the last glob. Filter by skill with `--tag <skill>`. Every case's `prompt.md` has `tags: [<skill>]`.
- On three writing cases (style guide, rewrite, release notes), Claude without the plugin already passes. They're regression guards. Only `first-pr-reply` shows the skill making a difference.
- An eval with a scaffold needs `--scaffold`. One that writes files or runs Bash needs `--allow-tools Bash Write Edit`.

Waiting on James (repo settings, so they need his yes): `bash skills/repo-setup/audit.sh jamesconwaydev/githard` reports this repo has no CODEOWNERS, no DCO check in CI, Dependabot alerts off and web-commit sign-off off. The plugin icon is still open too.

Next: M2, starting with #5 (`contributors`).

## 2026-11-08 ~21:00 UTC: audit gaps closed

James's standing rule: fix every gap and bug found along the way, don't just report it. GitHard is for new and existing orgs and repos alike, and `docs/design.md` now says so.

Done: Dependabot alerts and web-commit sign-off are on (both API calls). This PR adds CODEOWNERS and a `dco` CI job. Once it merges, `dco` gets added to the `protect-main` ruleset as a required check.

Note: `CLAUDE.md` is in James's global git ignore, so it isn't in the repo. Changes to it only apply on his machine.

Next: #5 (`contributors`). The icon is still waiting on James.

## 2026-11-08 ~23:30 UTC: moved to getgithard

The repo now lives at `getgithard/githard`, and GitHub redirects the old `jamesconwaydev/githard` URLs. James created the org. The audit passes 21 of 21 at the new address. James also asked GitHub Support about the inactive `githard` username. If it's released, rename the org.

Done since the last entry: #6 `fork-pr-safety` and the `fork-pr-reviewer` agent (#26). Fork CI approval for this repo is now `all_external_contributors`. #27 fixed the not-built sentence going missing from the final answer, and replaced the stale `planned-fork-pr` eval with `planned-merging`. In the full eval run, every case passes with the plugin.

In progress: the website (`getgithard/githard-site`), with the home page on githard.dev and the docs on docs.githard.dev, both on Cloudflare Pages. Also Tank, the bulldog mascot, rendered locally with Z-Image-Turbo (`mflux`, `-q 8`).

Next: #7 (`issues-and-roadmap`).

## 2026-11-08 ~23:10 UTC: M3 under way, site live

Done since the last entry:
- #7 `issues-and-roadmap` (#36). This repo now has issue types, a public board (getgithard project 1) with sizes, #16 blocking #17 blocking #18, and starter issues #30 to #35. The pool is at 6 of 10.
- #8 `merging` (#37). `merge-when-green.sh` merged its own PR. Skills use `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PLUGIN_ROOT}` now.
- `audit.sh` honours `.github/audit-skip` (#29).
- The site is live: githard.dev and docs.githard.dev, from `getgithard/githard-site`, on Cloudflare Pages with Git integration. Its projects are `githard` (output `www`) and `githard-docs` (root `docs`). Tank is final.

Images for James are in `~/Desktop/GitHard uploads/`: `org-avatar.png` and the social previews.

Gotchas:
- Image generation: Z-Image-Turbo through `mflux`, run with `-q 8 --low-ram`. It peaks at 26 GB, takes about 14 minutes an image, and only one can run at a time. Rebuild the site images with `scripts/make-assets.py CUTOUT HEAD_BOX OUT`, after a `rembg -m isnet-anime` cutout.
- Headless Chrome won't go narrower than about 500 px. Check mobile layouts with Playwright's iPhone 13 device.
- When a skill ships, retarget the `planned-*` eval that names it (see `evals/README.md`).

Next: #9 (`releases`).

## 2026-11-09 01:30 UTC: every planned skill is built

Done: M3 and M4 are closed. That's #9 `releases` (#39), #10 `docs-honesty` and the `docs-auditor` agent (#40), #11 `org-setup` (#41, with the bootstrap fix in #42), #12 `security-baseline` (#43, with the Scorecard follow-up in #45), #13 `growth` (#44), and #14 `save-point` (#46). Plus `audit-docs.sh` ignoring example URLs in code (#47). All 13 skills pass their evals with the plugin, 42 cases in all. The site lists every drill, Tank sits on the section edge, and in-page links scroll smoothly.

Org: `getgithard/.github` exists, made with `bootstrap-dotgithub.sh`, and passes the repo audit. githard.dev is verified, hello@githard.dev is the public email, 2FA is required, and both repos are pinned. GitHard's first Scorecard was 6.3/10. CodeQL (actions) has been added since. Secret scanning and push protection are on for all three repos.

Next: M5. #15 dogfood needs a brand-new org from James. Then #16 (README before and after), #17 (first release, `claude plugin tag`), and #18 (launch).

Waiting on James:
- `gh api -X PATCH orgs/getgithard -f description=... -F web_commit_signoff_required=true`. The org audit still shows both missing.
- Submitting the OpenSSF Best Practices badge at bestpractices.dev.

Gotchas:
- When a skill ships, retarget or remove its `planned-*` eval and its topics in `using-githard`'s description. None are planned now.
- Grader regexes are JavaScript. Use `flags: i`, never inline `(?i)`.
- Auto mode blocks org-setting changes and running downloaded binaries. Hand those to James.
- `githard-site` stays public on purpose: a free org can't enforce rulesets on private repos.

## 2026-11-09 03:40 UTC: keyparity v0.1.0 shipped with GitHard

Done since the last section:
- New skills: `openssf-badge` (#54) and `agent-toolkit` (#56). GitHard holds the OpenSSF Best Practices passing badge (project 16471). The path to gold is #59.
- githard.dev and docs.githard.dev send hardened headers (githard-site#6). The Pages projects are `githard-site` and `githard-docs`, not `githard`.
- Dogfood (#15): keyparity/keyparity, a Bun CLI, went from an empty org to a published v0.1.0 using GitHard's skills, with 40 tests and attested binaries. Six GitHard gaps were found and fixed (#60, #61, #63).

Next:
1. npm publishing for keyparity (James's npm account).
2. keyparity's org steps (2FA, `.github` repo, pins) and its OpenSSF badge.
3. GitHard silver (#59): GOVERNANCE, ROADMAP, ARCHITECTURE, SECURITY-MODEL, shellcheck, coverage.
4. M5: #16 (README before and after, now possible with keyparity), #17 (release githard--v0.1.0), #18 (launch).

Waiting on James: npm for keyparity. A second owner for getgithard (silver `access_continuity`).

Gotchas:
- Auto mode blocks creating public repos, org PATCH calls, and writing `.claude/` in the working repo. Use `bootstrap-repo.sh` and `bootstrap-dotgithub.sh`, and hand over the commands. James may add `/permissions` rules for his two orgs.
- James's global gitignore excludes `**/.claude/` and `CLAUDE.md`. Shared `.claude/settings.json` needs `git add -f`.
- Cloudflare caps a header line at about 2,000 characters. The docs CSP is 1,838, and `csp-headers.py` fails the build past 2,000.

## 2026-11-09 05:30 UTC: githard--v0.1.0 released

Done:
- **githard--v0.1.0** is published, with an attested source tarball. The release workflow runs on `githard--v*` tags. A clean config installs 0.1.0 with 15 skills and 2 agents. #16 and #17 are closed.
- **README** has a real before and after (keyparity's org audit) and the install line. The site and docs say how to install.
- **First outside contribution:** @foothillsdigital, #73, thanked in the release notes. `unanswered.sh` now flags unanswered issue claims too (#71).
- **keyparity:** 0.1.2 is on npm (the 0.1.1 default-path bug is fixed, and 0.1.1 is deprecated). Its org audit passes, apart from two items skipped on purpose. It has the OpenSSF passing badge (16475).
- **OpenSSF for GitHard (16471):** 196 of 300, with every silver criterion answered. The docs (#66), shellcheck (#67) and the Brewfile (#76) are in.

Next:
1. #77: test coverage (a stub `gh` plus kcov) for silver.
2. #18: launch. It needs James's choice of channels. Use the `growth` skill.
3. A second getgithard owner (James), then silver.

Gotchas:
- npm uses staged publishing for this account: `npm stage publish`, then `npm stage approve <id>`, which needs 2FA in a browser.
- Auto mode blocks publishing releases and merging outside contributors' PRs. Hand both to James with the exact command.
- The release smoke test should run binaries from inside a project with default flags. That's how the 0.1.1 bug slipped past.

## 2026-11-09 05:45 UTC: paused for James's review

**Paused on purpose.** James is reviewing GitHard and keyparity overnight. Next session: start by asking James for his findings, make the changes he asks for, and only then move on (#18 launch or #77 coverage, his choice). Don't start new work before he's shared them.

**Where things are** (all on `main`, clean, no open PRs, merged branches deleted):

| Local folder (`~/Documents/GitHub/`) | Remote | State |
|---|---|---|
| `githard` | getgithard/githard | v0.1.0 released, 15 skills, OpenSSF 16471 at passing (196/300) |
| `githard-site` | getgithard/githard-site | githard.dev and docs.githard.dev live on Cloudflare Pages (`githard-site`, `githard-docs`) |
| `keyparity` | keyparity/keyparity | v0.1.2 on GitHub and npm, OpenSSF 16475 at passing |
| `getgithard-dotgithub` | getgithard/.github | not a git checkout. Change it, then re-run `bootstrap-dotgithub.sh`, which opens a PR |
| `keyparity-dotgithub` | keyparity/.github | same as above |

**Open issues worth knowing:** #18 (launch), #59 (silver, then gold), #77 (coverage), #15 (dogfood log, all eight gaps fixed), keyparity v0.2.0 (#18, #19, #20 are starter issues for contributors).

**To check everything is healthy after a restart:**
```sh
cd ~/Documents/GitHub/githard && git pull && scripts/check.sh
bash skills/repo-setup/audit.sh getgithard/githard
bash skills/contributors/unanswered.sh getgithard/githard
bash skills/contributors/unanswered.sh keyparity/keyparity
bash skills/openssf-badge/badge-status.sh 16471 silver
```

Not ours, so leave them alone: a podman VM, a Playwright test server and a merge script from another project may be running on this Mac.

## 2026-11-10 UTC: on-duty designed, plan written

**Done:**
- `unanswered.sh` now checks issues even when no PRs are open (#80). That bug hid a claim on keyparity#18.
- @O1sumitkumar is assigned keyparity#18 (Ruby scanning) and has been welcomed.
- James approved the design for `on-duty`, which looks after a repo 24/7 in full auto or safe mode, on each project's own Claude account: `docs/on-duty.md` (#81).

**In progress:**
- The implementation plan is at `docs/superpowers/plans/2026-11-10-on-duty.md`. It's local only, because James's global git ignore excludes `docs/superpowers/`.
- It's waiting on James to review the plan and pick the execution method. Its Task 0 creates milestone M6 and the issue.

**Next:**
- Build on-duty once James approves the plan.
- Watch for @O1sumitkumar's PR on keyparity#18. It's a first-time fork PR, so read the diff before approving CI.
- #18 launch and #77 coverage are still waiting on James's choice.

## 2026-11-10 22:18 UTC: on-duty merged

**Done:**
- `on-duty` merged in #84 (fixes #83). It covers the skill, the workflow template and its config, and the act, gate, queue and spend scripts. It also adds `next-version.sh`, plus `--head`, `--require` and `--allow-fork` on the merge and approve-runs scripts. With the plugin, all 5 evals pass. Without it, 3 of the 5 fail.
- In #85, `unanswered.sh` stopped printing `@null` for an issue that only bots had answered.

**Not proven yet:**
- Nothing in on-duty has run against real GitHub. The live checklist is in the local SDD reports at `~/Documents/GitHub/githard-on-duty/.superpowers/sdd/2026-11-10-on-duty/task-6-report.md` and `task-7-report.md`. The three biggest unknowns:
  - whether `GH_TOKEN` survives claude-code-action's environment scrub;
  - whether the narrowed Write rule can create the proposals file;
  - whether the job token can read check status.
- The README and the release notes don't mention on-duty until it ships in a release.

**Next:**
- A live test needs a scratch repo, or keyparity, with James's **own** Claude secret and PAT. Only James can choose to set that up.
- Parked: an approved merge card that times out stays suppressed. Exit code 2 also means "some merges were deferred".
- Watch for @O1sumitkumar's PR on keyparity#18 (fork, so read the diff before approving CI).

## 2026-11-10 23:46 UTC: on-duty is on keyparity, waiting on one secret

**Done:**
- On-duty's setup PR is merged on keyparity (keyparity#29). It's in safe mode with `chat: approve`, `identity: maintainer` and `monthly_cap_usd: none`, and GitHard is pinned to `aa17b7b` on main, since no release includes on-duty yet. These are James's answers: his own account, every reply waits, no disclosure line, no cap.
- On keyparity, `CLAUDE_CODE_OAUTH_TOKEN` is set with a real value (updated 23:14:32Z).
- No `AI_POLICY.md` was added. With no policy, on-duty adds no bot line, which is the "no disclosure" James chose.

**Waiting on James:**
- `GITHARD_TOKEN` on keyparity still holds an **empty** value from 23:08:44Z. He lost the PAT and is making a new one. The steps he has:
  1. Go to https://github.com/settings/personal-access-tokens, delete any old `githard keyparity` token, and click **Generate new token**.
  2. Name it `githard keyparity`, with owner `keyparity` and only the `keyparity` repo. Give it Read and write on Contents, Issues, Pull requests, Actions and Variables.
  3. Paste it with the pencil next to `GITHARD_TOKEN` at https://github.com/keyparity/keyparity/settings/secrets/actions, then click **Update secret**.
- The GitHard setup PR #87 is open and green. Merging it was blocked for me, so James merges it, but only after keyparity works.

**Next:**
1. Check it's saved: `gh secret list -R keyparity/keyparity --json name,updatedAt`. `GITHARD_TOKEN` must be newer than 23:08:44Z.
2. Start a run: `gh workflow run githard-on-duty.yml -R keyparity/keyparity`, then read its log with `gh run view --log`.
3. Check the log against the live checklist in `~/Documents/GitHub/githard-on-duty/.superpowers/sdd/2026-11-10-on-duty/task-6-report.md` and `task-7-report.md`. The three to settle first:
   - does `GH_TOKEN` survive the action's environment scrub;
   - can the narrowed Write rule create the proposals file;
   - can the job token read check status.
4. Once keyparity works, do githard: merge #87, then set both secrets on `getgithard/githard`, with a second PAT owned by `getgithard`.

**Gaps to fix:**
- Neither repo's release flow works with on-duty. keyparity's `release.yml` needs `package.json` already bumped, and on-duty doesn't write code. githard's releases come from pushing a tag, so on-duty refuses them. In safe mode this only means a release card, so nothing is broken.
- An approved merge card that times out isn't retried, and exit code 2 also means "some merges deferred". Both are parked.

**Gotchas:**
- Commands run with `! ` can't take typed input. `! gh secret set NAME` saved an empty secret three times, and `! claude setup-token` hung. James should set secrets on GitHub's secrets page and run `claude setup-token` in his own Terminal app. Never use `--body`, because the token would end up in the transcript.
- Claude Code's safety check refuses to let me merge a PR that adds a spending workflow ("Merge Without Review"). James merges those himself.
- `gh pr merge --delete-branch` switches the local clone to main, so a later `gh pr view` with no number fails. Name the PR number.
- Nothing is running in the background.
