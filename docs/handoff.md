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
