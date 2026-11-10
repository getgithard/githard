#!/usr/bin/env bash
# Work out the next version from Conventional Commit messages.
# Usage: git log --format='%s%n%b' LAST_TAG..HEAD | bash next-version.sh LAST_TAG
# LAST_TAG is [prefix--]vX.Y.Z; a prefix is kept. Prints vX.Y.Z (any feat is a minor bump, else any
# fix or perf is a patch), "breaking vX.0.0" (a type!: subject or a BREAKING CHANGE: line), or none.
# Exit: 0 printed an answer, 2 LAST_TAG isn't a version tag (nothing on stdout).
set -uo pipefail
tag=${1:-}
n='(0|[1-9][0-9]*)' # semver forbids leading zeros
re="^(.*--)?v$n\\.$n\\.$n\$"
[[ $tag =~ $re ]] || { echo "next-version.sh: '$tag' is not [prefix--]vX.Y.Z" >&2; exit 2; }
pre=${BASH_REMATCH[1]} major=${BASH_REMATCH[2]} minor=${BASH_REMATCH[3]} patch=${BASH_REMATCH[4]}
level=none
shopt -s nocasematch # bash 3.2 has no ${x,,}
b='^([*-][[:space:]]+)?' # squash-merge bodies bullet each commit
# Drain stdin (no break) so an upstream git log never meets SIGPIPE.
while IFS= read -r line || [ -n "$line" ]; do
  if [[ $line =~ ${b}BREAKING[\ -]CHANGE: ]] || [[ $line =~ ${b}[a-z]+(\([^\)]*\))?!:[[:space:]] ]]; then level=breaking; fi
  [[ $level == breaking ]] && continue
  [[ $line =~ ${b}feat(\([^\)]*\))?:[[:space:]] ]] && level="minor"
  [[ $level != minor && $line =~ ${b}(fix|perf)(\([^\)]*\))?:[[:space:]] ]] && level="patch"
done
case $level in
  breaking) echo "breaking ${pre}v$((major + 1)).0.0" ;;
  minor) echo "${pre}v$major.$((minor + 1)).0" ;;
  patch) echo "${pre}v$major.$minor.$((patch + 1))" ;;
  *) echo none ;;
esac
