#!/usr/bin/env bash
# An existing repo whose PR workflow runs a fork's code with secrets.
set -euo pipefail
git init -q .
printf '# jot\n\nA notes app.\n' > README.md
mkdir -p .github/workflows
cat > .github/workflows/preview.yml <<'YML'
name: preview
on: pull_request_target
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.event.pull_request.head.sha }}
      - run: npm ci && npm run build
      - run: npx deploy-preview ./dist
        env:
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
YML
