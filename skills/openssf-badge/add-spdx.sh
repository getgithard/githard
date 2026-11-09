#!/usr/bin/env bash
# Add copyright and SPDX license lines to source files that lack them, for the gold criteria
# copyright_per_file and license_per_file.
# Usage: bash add-spdx.sh "COPYRIGHT HOLDER" SPDX-ID [--check] [PATH...]
#   e.g. bash add-spdx.sh "The jot authors" MIT
# Handles files whose comments start with # (shell, Python, YAML, Ruby...) or // (JS, TS, Go,
# Rust, C...). Keeps a shebang line first. Skips files that already have SPDX-License-Identifier.
# --check changes nothing and exits 1 if any file needs the lines.
set -uo pipefail
holder=${1:?usage: bash add-spdx.sh "HOLDER" SPDX-ID [--check] [PATH...]}
spdx=${2:?usage: bash add-spdx.sh "HOLDER" SPDX-ID [--check] [PATH...]}
shift 2; check=0
[ "${1:-}" = --check ] && { check=1; shift; }
year=$(date +%Y); need=0
files=$(git ls-files -- "${@:-.}" 2>/dev/null) || { echo "run it inside a git repo"; exit 2; }
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case $f in
    *.sh|*.bash|*.py|*.rb|*.pl|*.yml|*.yaml|*.toml) c='#' ;;
    *.js|*.mjs|*.cjs|*.ts|*.tsx|*.jsx|*.go|*.rs|*.c|*.h|*.cc|*.cpp|*.hpp|*.java|*.kt|*.swift|*.cs) c='//' ;;
    *) continue ;;
  esac
  head -5 "$f" | grep -q 'SPDX-License-Identifier' && continue
  need=1
  if [ $check = 1 ]; then echo "needs    $f"; continue; fi
  tmp=$(mktemp)
  if head -1 "$f" | grep -q '^#!'; then
    { head -1 "$f"; printf '%s Copyright %s %s\n%s SPDX-License-Identifier: %s\n' "$c" "$year" "$holder" "$c" "$spdx"; tail -n +2 "$f"; } > "$tmp"
  else
    { printf '%s Copyright %s %s\n%s SPDX-License-Identifier: %s\n' "$c" "$year" "$holder" "$c" "$spdx"; cat "$f"; } > "$tmp"
  fi
  cat "$tmp" > "$f"; rm -f "$tmp"; echo "added    $f"
done <<<"$files"
[ $check = 1 ] && [ $need = 1 ] && exit 1
exit 0
