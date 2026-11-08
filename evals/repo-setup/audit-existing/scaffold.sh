#!/usr/bin/env bash
# A small Node CLI with a README, LICENSE and CI, and most of the rest missing.
set -euo pipefail
git init -q .
printf '# tidy\n\nRenames files in a folder to lowercase-with-dashes.\n' > README.md
printf 'MIT License\n\nCopyright (c) 2026 Sam\n' > LICENSE
printf '{ "name": "tidy", "version": "0.1.0", "scripts": { "test": "node --test" } }\n' > package.json
mkdir -p .github/workflows
cat > .github/workflows/test.yml <<'YML'
name: test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - run: npm test
YML
cat > .github/dependabot.yml <<'YML'
version: 2
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
YML
