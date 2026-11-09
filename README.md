# GitHard

[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/16471/badge)](https://www.bestpractices.dev/projects/16471)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/getgithard/githard/badge)](https://scorecard.dev/viewer/?uri=github.com/getgithard/githard)

Boot camp for your GitHub repos.

You've got an idea, a GitHub account and no maintainer experience. GitHard is a Claude Code plugin that sets up your org and repos the way you'd want them a year from now, then helps you run them: issues people can actually finish, a safe way to take contributions from strangers, merges that wait for green, releases you can verify, and docs that only say what's true.

It's built from what worked, and what broke, while running a real open-source project from its first commit.

## Proof: keyparity, from an empty org

We gave GitHard an empty GitHub org and a one-page plan for a small CLI, and let it do the rest. That became [keyparity](https://github.com/keyparity/keyparity), which checks that the env vars your code reads are in `.env.example` and GitHub Secrets.

The org, the moment it was created:

```
$ bash org-audit.sh keyparity
missing  display name
missing  description
missing  website
missing  public email
missing  verified domain
missing  2FA required for members
missing  sign-off required on web commits
ok       members get read access by default
missing  public .github repo (profile README and default community files)
missing  pinned repos
```

The same org after GitHard. The two skipped items were the owner's call: keyparity has no domain, and no public email.

```
$ bash org-audit.sh keyparity --skip "verified domain" --skip "public email"
ok       display name
ok       description
ok       website
skipped  public email
skipped  verified domain
ok       2FA required for members
ok       sign-off required on web commits
ok       members get read access by default
ok       public .github repo
ok       .github has profile/README.md
ok       .github has CONTRIBUTING.md
ok       .github has SECURITY.md
ok       .github has CODE_OF_CONDUCT.md
ok       .github has default issue templates
ok       pinned repos (1)
```

| | Before | After |
|---|---|---|
| Repo setup audit | no repo | 22 of 22 checks pass |
| Releases | none | [v0.1.2](https://github.com/keyparity/keyparity/releases/latest): five binaries with checksums and build attestations, plus [npm](https://www.npmjs.com/package/keyparity) |
| OpenSSF Best Practices | no project | [passing](https://www.bestpractices.dev/projects/16475) |
| Work for newcomers | none | [three scoped good first issues](https://github.com/keyparity/keyparity/issues?q=is%3Aopen+label%3A%22good+first+issue%22) |

Every pull request went through CI and a DCO check, and GitHard's merge script merged each one only when its checks were green on the exact commit tested. Along the way GitHard hit eight gaps in itself, and each one is fixed. They're logged in [#15](https://github.com/getgithard/githard/issues/15).

## What's in it

Fourteen skills, each with evals that run with and without the plugin:

- **Setting up:** `repo-setup`, `org-setup`, `agent-toolkit` (the Claude Code plugins, MCP servers and language servers a project needs)
- **People:** `contributors`, `fork-pr-safety`, `issues-and-roadmap`
- **Shipping:** `merging`, `releases`, `docs-honesty`
- **Security:** `security-baseline`, `openssf-badge` (from passing to gold)
- **Everything else:** `writing`, `growth`, `save-point`, and `using-githard`, which sends each request to the right one

The docs are at [docs.githard.dev](https://docs.githard.dev).

## Status

**Not released yet.** The first release, `githard--v0.1.0`, is planned before the new year, and this README will show the install command once it's out. Until then you can read every skill [here](skills/), and follow the build in [`docs/plan.md`](docs/plan.md).

## Contributing

Ideas and bug reports are welcome in [Issues](https://github.com/getgithard/githard/issues) and [Discussions](https://github.com/getgithard/githard/discussions). See [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request, and [GOVERNANCE.md](GOVERNANCE.md) for how decisions get made.

## License

[MIT](LICENSE)
