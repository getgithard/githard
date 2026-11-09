# Contributing to GitHard

Thanks for helping. GitHard is early, so the most useful things right now are ideas, bug reports and reviews of the skills as they land.

## Before you start

- **Look at [`docs/plan.md`](docs/plan.md)** to see what's being built and in what order. Each item is an issue.
- **Claim an issue by commenting on it** before you start, so two people don't build the same thing. You'll be assigned.
- **For a new skill idea**, open a Discussion or a "Skill idea" issue first. Skills are cheap to write and expensive to keep sharp, so we agree on scope before code.

## Pull requests

- Branch from `main`, and keep each PR to one change. One skill per PR.
- Sign off every commit (`git commit -s`). That's the [Developer Certificate of Origin](https://developercertificate.org/): you're saying you have the right to contribute the change.
- Run `claude plugin validate .` before you push. CI runs the same checks GitHard can run without Claude.
- Write in the house voice ([`knowledge/voice.md`](knowledge/voice.md)), and never describe something that isn't built yet.
- If your PR is from a fork, a maintainer approves its CI runs after reading the diff. If `main` moves on, use the **Update branch** button on your PR. We won't push to your branch.

## AI help

AI-assisted contributions are welcome. You're responsible for every line you submit: read it, test it, and be ready to explain it.

## When a pull request goes quiet

If a PR has had no activity for 30 days, a maintainer checks in. At 60 days we either close it or finish it ourselves and credit you. There's no stale bot.

## Code review

Every change reaches `main` through a pull request, and its checks must pass. A reviewer checks that the change:

- does what the PR says, and nothing it doesn't say
- comes with eval cases for skill behaviour, or a `scripts/check.sh` test for scripts
- doesn't weaken security: secrets, permissions, pinned Actions, untrusted input
- updates the docs along with the behaviour

GitHard has one maintainer today, so most PRs are reviewed by their author before they merge. Outside PRs always get a maintainer review. Gold needs at least half of the changes in a release reviewed by someone other than the author, and that waits on a second maintainer. See [GOVERNANCE.md](GOVERNANCE.md).
