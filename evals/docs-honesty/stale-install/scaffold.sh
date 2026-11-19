#!/usr/bin/env bash
# Copyright 2026 James Conway
# SPDX-License-Identifier: MIT
# A CLI whose README is right for v1.2.0, while its docs folder's install page still installs v1.1.0
# and points at a schema asset the v1.2.0 release doesn't ship.
set -euo pipefail
git init -q .
cat > README.md <<'MD'
# jot

Plain-Markdown notes from your terminal.

```sh
jot add "buy milk"
jot list --json
```

Run `jot --help` for every command.
MD
mkdir -p docs
cat > docs/install.md <<'MD'
# Install jot

```sh
curl -fsSLO https://github.com/me/jot/releases/download/v1.1.0/jot-darwin-arm64.tar.gz
tar -xzf jot-darwin-arm64.tar.gz && mv jot /usr/local/bin/
```

## Editor support

Point your editor at the config schema to get completion in `jot.toml`:

https://github.com/me/jot/releases/latest/download/jot-config.schema.json
MD
cat > release-v1.2.0.json <<'JSON'
{
  "tagName": "v1.2.0",
  "publishedAt": "2026-11-16T10:00:00Z",
  "body": "## v1.2.0\n- `jot list --json` prints notes as JSON (#88)\n- Fixed: notes with an emoji in the title no longer fail to save (#91)",
  "assets": [
    {"name": "jot-darwin-arm64.tar.gz"},
    {"name": "jot-linux-amd64.tar.gz"},
    {"name": "config.schema.json"},
    {"name": "checksums.txt"}
  ]
}
JSON
cat > help-1.2.0.txt <<'TXT'
Usage: jot <command> [flags]

Commands:
  add <text>     Add a note
  list           List notes   (--json)

Flags:
  --json         Print JSON
  --version      Print the version
TXT
