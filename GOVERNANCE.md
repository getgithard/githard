# Governance

## How decisions get made

GitHard has one maintainer today, James Conway (@jamesconwaydev), who makes the final call. Most decisions happen in public, in pull requests and issues. A change merges when it meets the review standards in [CONTRIBUTING.md](CONTRIBUTING.md) and its checks pass. Anything bigger, such as a new skill or a change to how the project runs, starts as an issue or a discussion, and the reasoning stays in that thread.

## Roles

| Role | Who | What they do |
|---|---|---|
| Lead maintainer | @jamesconwaydev | Sets direction, reviews and merges PRs, cuts releases, owns the getgithard org, its settings and githard.dev |
| Maintainer | none yet | Reviews and merges PRs, triages issues, answers security reports |
| Contributor | anyone | Opens issues, discussions and PRs. See [CONTRIBUTING.md](CONTRIBUTING.md) |

How to become a maintainer: after several merged PRs and reviews, a maintainer suggests it in a discussion, and the lead maintainer decides.

Claude Code does much of the day-to-day GitHub work under the lead maintainer's account, following [`CLAUDE.md`](CLAUDE.md)'s rules. It merges only on passing checks, and asks before anything that touches money, legal questions, account settings or people.

## If someone can't continue

The project should keep going if any one person is lost, within a week. Today it can't:

- One person (@jamesconwaydev) has owner access to the getgithard org, can publish releases, and controls githard.dev and its Cloudflare account.
- 2FA is required for every org member.

Fixing that means adding a second owner. That's tracked in [#59](https://github.com/getgithard/githard/issues/59), and it's a criterion for the OpenSSF silver badge, which GitHard doesn't claim until it's true.
