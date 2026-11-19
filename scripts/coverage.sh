#!/usr/bin/env bash
# Statement coverage of the skills' shell scripts, measured with kcov while scripts/check.sh runs.
# Usage: bash scripts/coverage.sh [MIN_PERCENT] [OUT_DIR]
# Every script under skills/ counts, run or not, so one with no test pulls the total down.
# Exits 1 below MIN_PERCENT (default 80). kcov runs best on Linux: CI uses the kcov/kcov image.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
min=${1:-80}; out=${2:-$(mktemp -d)}
kcov --include-path="$PWD/skills" --include-pattern=.sh --bash-parse-files-in-dir="$PWD/skills" "$out" scripts/check.sh >/dev/null 2>&1 ||
  echo "note     check.sh failed under kcov, so the numbers below may be low"
cov=$(find "$out" -path "*/kcov-merged/coverage.json" -o -path "*/check.sh*/coverage.json" | sort | tail -1)
[ -n "$cov" ] || { echo "unknown  kcov wrote no coverage.json to $out"; exit 2; }
jq -r --arg root "$PWD/" '.files | sort_by(.percent_covered | tonumber)[]
  | "file     \(.percent_covered)%  \(.covered_lines)/\(.total_lines)  \(.file | ltrimstr($root))"' "$cov"
total=$(jq -r .percent_covered "$cov")
echo "total    $total% of statements, minimum $min%"
jq -e --argjson m "$min" '(.percent_covered | tonumber) >= $m' "$cov" >/dev/null
