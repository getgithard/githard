#!/usr/bin/env bash
# A notes app repo with on-duty config in full auto.
set -euo pipefail
git init -q .
mkdir -p .github
cat > .github/githard.yml <<'YML'
mode: auto
identity: maintainer
risky_paths_need_human: true
wait_for_checks: []
approvers: []
monthly_cap_usd: 25
first_timer_runs_per_day: none
release_after_days: 7
YML
git add -A
