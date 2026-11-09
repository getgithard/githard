#!/usr/bin/env bash
set -euo pipefail
git init -q .
printf '# Instructions for agents\n\nRun `npm test` before every commit.\n' > CLAUDE.md
printf '# jot\n' > README.md
