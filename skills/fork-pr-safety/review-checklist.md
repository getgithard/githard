# Reviewing a fork PR

When CI runs, the PR's code runs on the project's runners. So the review looks for anything that would run, and anything that doesn't match what the PR says it does.

The review only reads. Use only commands that read: `gh pr view`, `gh pr diff`, `gh api` with GET, and `git` commands that read. Don't approve, comment, push, check out the branch into the user's working tree, or merge while reviewing.

## What to read

1. `gh pr view <N> --repo <OWNER/REPO> --json title,body,author,headRefOid,files,commits`
2. `gh pr diff <N> --repo <OWNER/REPO>`. Read every line. Don't sample it and don't skim it.

If all you have is a saved diff file, read all of it, and take the title and description from the user.

## What to look for

- **Anything under `.github/`:** workflows, actions, Dependabot, CODEOWNERS. Always flag these for the owner, however small they are.
- **Code that runs during install, build or test:** `package.json` scripts (`preinstall`, `postinstall`, `prepare`, `pretest`), `Makefile`, `setup.py`, `pyproject.toml` build hooks, `build.rs`, `conftest.py`, Dockerfiles, shell scripts, git hooks.
- **Dependency changes:** new packages, changed lockfiles with no matching change in the manifest, git or URL dependencies, names one typo away from a popular package.
- **Hidden content:** base64 or hex blobs, minified code, binaries, `curl | sh`, network calls in tests, reads of environment variables or secrets.
- **Mismatch:** files or behaviour the title and description don't account for.

## Report

Settle on one verdict:

- `SAFE TO RUN CI`: nothing above was found.
- `OWNER MUST REVIEW`: something touches `.github/`, secrets, or code that runs in CI, but it looks intentional.
- `DON'T RUN CI`: something looks hidden, malicious, or unrelated to the stated change.

Then give the head commit SHA you read, and one line per finding as `path:line: what it does, and why it matters`. Say "no findings" if there are none. Finish with any file you couldn't read.
