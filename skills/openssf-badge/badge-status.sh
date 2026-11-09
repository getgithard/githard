#!/usr/bin/env bash
# What stands between a project and the next OpenSSF Best Practices badge level.
# Usage: bash badge-status.sh PROJECT_ID [passing|silver|gold]
#   PROJECT_ID is the number in https://www.bestpractices.dev/projects/PROJECT_ID.
#   With no level, it targets the level after the one the project holds.
# Reads the project's own answers from bestpractices.dev, then lists, for the target level and
# the levels below it: MUSTs not yet Met, MUSTs not yet answered, then SHOULDs. Criteria marked
# "needs others" depend on other people (a second reviewer, more maintainers) and can't be
# met by settings. Exits 0 when nothing blocks the target, 1 otherwise, 2 if no answer.
set -uo pipefail
id=${1:?usage: bash badge-status.sh PROJECT_ID [passing|silver|gold]}
here=$(cd "$(dirname "$0")" && pwd)
p=$(curl -sf --max-time 20 "https://www.bestpractices.dev/projects/$id.json") ||
  { echo "unknown  couldn't read project $id from bestpractices.dev"; exit 2; }
current=$(jq -r '.badge_level // "in_progress"' <<<"$p")
case $current in in_progress) next=passing ;; passing) next=silver ;; *) next=gold ;; esac
target=${2:-$next}
case $target in passing) levels="passing" ;; silver) levels="passing silver" ;; gold) levels="passing silver gold" ;;
  *) echo "level must be passing, silver or gold"; exit 2 ;; esac
jq -r '"project  \(.name // .repo_url // "project"): \((.badge_level // "in_progress") | sub("_"; " ")) now (\(.tiered_percentage // 0) of 300 on the tiered scale)"' <<<"$p"
echo "target   $target"

blocking=0; out=""
for level in $levels; do
  while IFS=$'\t' read -r crit lvl req others; do
    [ "$lvl" = "$level" ] || continue
    status=$(jq -r --arg k "${crit}_status" '.[$k] // "?"' <<<"$p")
    case $status in Met|N/A) continue ;; esac
    tag=$([ "$others" = yes ] && echo " (needs others)")
    if [ "$req" = MUST ]; then
      [ "$status" = "?" ] && kind="answer" || kind="unmet"
      out+="$kind	$level	$crit$tag"$'\n'; blocking=1
    else
      out+="$(tr '[:upper:]' '[:lower:]' <<<"$req")	$level	$crit$tag"$'\n'
    fi
  done < <(grep -v '^#' "$here/criteria.tsv")
done
# Unmet first, then unanswered, then the SHOULDs and SUGGESTEDs.
for kind in unmet answer should suggested; do
  grep "^$kind	" <<<"$out" | awk -F'\t' '{printf "%-9s %-8s %s\n", $1, $2, $3}'
done
[ $blocking = 0 ] && echo "nothing blocks $target. Fill in any SHOULDs you can, then submit." || true
exit $blocking
