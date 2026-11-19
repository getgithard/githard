#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# A CLI tagged v1.2.0, then a commit on main that adds `sync --watch` to both the code and the README.
# The README matches main, not the release.
set -euo pipefail
git init -q -b main .
git config user.name Sam; git config user.email sam@jot.example; git config commit.gpgsign false; git config tag.gpgSign false
cat > jot <<'SH'
#!/bin/sh
# jot: plain-Markdown notes from your terminal.
case "$1" in
  --help|"") printf 'Usage: jot <command>\n\nCommands:\n  add <text>   Add a note\n  list         List notes (--json)\n  sync         Sync once with the configured remote\n' ;;
  --version) echo "jot 1.2.0" ;;
esac
SH
chmod +x jot
cat > README.md <<'MD'
# jot

Plain-Markdown notes from your terminal.

```sh
jot add "buy milk"
jot list --json
jot sync
```
MD
git add -A; git commit -qm "feat: jot sync"; git tag -a v1.2.0 -m v1.2.0
sed -i.bak 's/  sync         Sync once with the configured remote/  sync         Sync with the configured remote (--watch keeps syncing)/' jot && rm jot.bak
cat >> README.md <<'MD'

`jot sync --watch` keeps syncing until you stop it.
MD
git add -A; git commit -qm "feat: jot sync --watch"
