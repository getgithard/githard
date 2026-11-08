#!/usr/bin/env bash
# A year-old project with a stale bot, a thin CONTRIBUTING and no AI policy.
set -euo pipefail
git init -q .
printf '# jot\n\nA notes app that keeps plain Markdown files.\n' > README.md
printf '# Contributing\n\nPRs welcome. Please add tests.\n' > CONTRIBUTING.md
mkdir -p .github/workflows
cat > .github/workflows/stale.yml <<'YML'
name: stale
on:
  schedule:
    - cron: "0 3 * * *"
jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/stale@v9
        with:
          days-before-stale: 30
          days-before-close: 7
YML
