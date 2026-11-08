#!/usr/bin/env bash
# A small CLI repo with its own writing rules in CONTRIBUTING.md that disagrees with GitHard's voice.
set -euo pipefail
git init -q .
cat > README.md <<'MD'
# tidy

TODO: intro
MD
cat > CONTRIBUTING.md <<'MD'
# Contributing

Open an issue before a large change. Run `./test.sh` before you push.

## Writing

All project text, including the README, follows these rules.

- Write in the third person. Never address the reader as "you".
- Do not use contractions.
- Refer to the reader as "the operator".
MD
cat > tidy.sh <<'SH'
#!/bin/sh
# tidy: renames files in a folder to lowercase-with-dashes.
SH
