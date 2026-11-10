#!/usr/bin/env bash
# A notes app repo owned by an org, with no on-duty files yet.
set -euo pipefail
git init -q .
git remote add origin https://github.com/example-org/notes-app.git
printf '# notes-app\n\nA small notes app.\n' > README.md
git add -A
