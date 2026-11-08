#!/usr/bin/env bash
# A CLI whose README documents a flag that merged after the v1.2.0 tag.
set -euo pipefail
git init -q .
cat > README.md <<'MD'
# jot

Plain-Markdown notes from your terminal.

```sh
jot add "buy milk"
jot list --json
jot sync --watch
```

`jot sync --watch` keeps your notes folder in sync with any remote you've set up.
MD
cat > CHANGELOG.md <<'MD'
## v1.2.0
- `jot list --json` prints notes as JSON (#88)
- Fixed: notes with an emoji in the title no longer fail to save (#91)

## Unreleased
- `jot sync --watch` (#97)
MD
cat > help-1.2.0.txt <<'TXT'
Usage: jot <command> [flags]

Commands:
  add <text>     Add a note
  list           List notes   (--json)
  sync           Sync once with the configured remote

Flags:
  --json         Print JSON
  --version      Print the version
TXT
