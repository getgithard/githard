# Lessons

What worked, and what went wrong, while running a real open-source project on GitHub from its first commit: a product repo, a website and docs repo, and more than a hundred small satellite repos, run by one maintainer with an AI agent doing most of the GitHub work. Every skill in GitHard should be built from these. Each lesson says what to do and why.

These are field notes, not finished skill text. When a skill uses one, it should say it plainly and in the house voice (`voice.md`).

## The working agreement between the owner and the agent

- **The agent acts, then reports.** It asks first only for money, account or ruleset changes, legal questions, disputes with people, and deletions that can't be undone. Approval for one kind of action doesn't carry over to the next.
- **Every request to the human is copy-paste ready.** Give the exact command with absolute paths, or numbered steps with the exact URL and button names. "Pin the issue" isn't an instruction; "open <url>, click … , then …" is.
- **Keep a save point.** A running handoff file holds the queue, the running jobs, what's owed to whom, and the gotchas learned that day. A fresh session reads its last section first.
- **Remember decisions where the next session will find them.** Durable preferences go in memory or the repo's agent instructions, not just in chat.

## Repo setup

- **Main is PR-only from day one.** Use a ruleset with required status checks and sign-off (DCO). Don't require the branch to be up to date with main: every merge would restart the next PR's CI, and a queue of ten PRs can take six hours.
- **Pin every GitHub Action to a full commit SHA**, with the version in a comment. Use Dependabot grouped monthly so updates don't flood the queue.
- **Community files on every repo:** README, LICENSE, CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, issue and PR templates, CODEOWNERS. An org's public `.github` repo gives default community files to every repo that lacks its own, and its `profile/README.md` is the org's front page.
- **New repos start with no ruleset and with private vulnerability reporting off.** Turn both on as part of creating a repo, not later.
- **Some things need the owner in the UI**, with no API: verifying the org's domain (a DNS TXT record plus an org email on that domain), pinning repos and discussions, and creating some accounts. Hand those over as steps.
- **An agent can be blocked from creating public repos.** Write an idempotent script that creates, pushes and tags, and have the human run it.

## Issues and the roadmap

- **Starter issues name the files to change, say how to test, give "done when" criteria, and say which files to stay out of.** Newcomers finish those. A well-scoped one was claimed within an hour.
- **Keep a deep pool of scoped issues**, around a hundred, so nobody waits for work. When the maintainers reach an issue nobody claimed, they take it themselves.
- **Fill in issue metadata:** type, milestone, project board card with a size, sub-issues and blocked-by links, and "Fixes #N" in the PR so the issue links to its PR.
- **"Writers wanted" issues bring in people who don't write code.** Writers are rarer on GitHub than developers. Be clear that the work is volunteer, and never hint at pay that doesn't exist.

## Contributors

- **Answer every outside PR quickly.** A watcher that only reports new activity misses older PRs, so also run a check that lists open outside PRs with no reply from a maintainer. One first-time contributor waited two days because of that gap.
- **Welcome every claim and assign the issue.** Tell first-timers up front about fork CI approval and the "Update branch" button.
- **Thank contributors by handle** in the release notes, and comment on their PR when it ships.
- **Reactions have a fixed meaning.** Use one per item, only on other people's posts: 🚀 for a claim or a new PR, 👀 while reviewing, 🎉 on merge, ❤️ for going beyond the ask, 👍 to acknowledge. Never 👎, 😄 or 😕. A reaction never replaces a reply someone is owed.
- **When a PR goes quiet,** a person checks in at 30 days. At 60 days, close it or finish it with credit. No stale bot.
- **When two people's work collides, say so, apologise for your side, and say which parts of theirs to keep.** Contributors take that well.

## Fork PRs and CI safety

- **Read the full diff before approving CI runs on a fork PR.** Changes to `.github/` or anything that runs with secrets go to the owner.
- **Never update a fork PR's branch or run a merge script on it.** With branch protection, a push the author didn't make needs another approval, and the owner can't approve their own push, so it deadlocks. Ask the contributor to click "Update branch".
- **Don't use GitHub's "Commit suggestion" in a DCO repo.** The commit has no sign-off, and DCO fails.
- **A push to a fork PR dismisses approvals and needs its CI approved again.** Re-approve the runs and the PR, then merge.
- **Approve only the runs on the PR's current head commit**, so a later push still waits for review.

## Merging

- **Merge with a script that waits for every required check on the PR's current head**, using the list of required checks from that repo's ruleset. A hard-coded list made other repos' PRs wait out a one-hour timeout.
- **Merge one PR at a time, and ride out CI flakes:** rerun only the failed jobs when every failure is a download that failed (a 5xx, a timeout or a reset), up to a limit. Anything else is a real failure.
- **Mind the API limit.** GitHub allows 5,000 GraphQL requests an hour, shared by every tool. Eleven merge jobs polling at once used it up, and loops that read a PR's state then got an empty answer and exited as if the PR were done. Run merges in one serial runner, and treat an empty answer as "unknown".
- **Never edit a running shell script.** Bash reads it as it runs. Write a new copy and move it into place.

## Releases

- **Cut the release only after the last fix merges.** A manually triggered workflow builds a draft. Verify the checksum, the attestation, the `version` output and a smoke test, then publish with the notes.
- **Keep the release notes as a running draft** and add each entry as its change merges. Each claim gets a test that checks the docs say only what shipped.
- **After every release:** update the README of every repo, regenerate the generated docs from the release tag, bump version pins in the install docs, and open issues for the work the release creates: testers wanted, docs gaps, and writers wanted.
- **Upgrade your own local copy right after a release.** An agent testing against an old binary hits bugs that are already fixed.

## Docs and the website

- **Audit the docs against the shipped code each release.** Compare schemas, CLI help, release notes and links. One release's notes pointed at a JSON Schema URL that returned 404, and its help text named a page that didn't exist.
- **Use real output in docs and videos.** Re-run every command with the released binary.
- **The homepage invites contributors.** Its latest-posts list comes from a daily rebuild.

## Security

- **Aim for a perfect OpenSSF Scorecard and Best Practices badge**, and be honest about the checks only other people can satisfy: a second reviewer and unaffiliated contributors.
- **Secrets live only in GitHub secrets.** They never appear in chat, logs, state files, import IDs or docs.
- **Don't copy an upstream's unsigned install path.** Download each file with a pinned sha256, install it by path, and say in the README exactly what's unsigned and what vouches for it.
- **Test containers share the runner's kernel.** A distro's userland can break on a newer host kernel. Print the failed units and the journal on failure, and confirm on a real VM before working around it in CI.

## Growth and outreach

- **Don't open "try our tool" issues on strangers' repos.** It reads as spam. Use the Show and tell category in a project's Discussions, and only where it's alive.
- **Grow through your own surfaces:** a directory of what you've built, a copy-me starter repo, help-wanted issues, an org profile, release posts, and short videos with real output.
- **Give back to the projects you depend on,** in small reviewed pieces, within each project's AI-contribution policy. Some ban AI help entirely; skip those, and say why if asked.
- **Check every launch channel against results.** One launch site brought nothing and isn't worth repeating.

## AI in the project

- **Publish an AI policy for contributors** (`AI_POLICY.md`): what's welcome, what must be disclosed, who is responsible. Banning AI help outright is a choice some projects make. A policy without a ban was enough here.
- **Respect each upstream's AI policy** before contributing to it.

## Building many small repos with subagents

- **Give every agent one shared brief file** (templates, rules, commit identity, a scan for leftover traces, a test matrix), and give each agent its own container prefix and port range so parallel tests don't collide.
- **Run an independent read-only review before publishing.** It catches real bugs every time.
- **Fix product bugs in the product.** Subagents dogfooding the product find bugs; don't work around them in the satellite repo.
