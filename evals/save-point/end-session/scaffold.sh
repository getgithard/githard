#!/usr/bin/env bash
set -euo pipefail
git init -q .
mkdir -p docs
cat > docs/handoff.md <<'MD'
# Handoff

## 2026-11-07 18:00 UTC: search index landed

Done: #40 (search index) merged.

Next: #44, the --json flag for `jot list`.
MD
