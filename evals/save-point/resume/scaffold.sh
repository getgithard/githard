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
cat >> docs/handoff.md <<'MD'

## 2026-11-08 17:30 UTC: --json flag waiting on CI

Done: #44 (--json for `jot list`) opened as PR #46.

Next: merge PR #46 once CI is green, then start #47 (export to HTML).

Owed: a reply to @lena-r on PR #45. She asked whether to rebase, and I said I'd answer today.

Gotchas: the Windows CI job flakes on downloads; rerun failed jobs only.
MD
