#!/usr/bin/env bash
# Read and check the on-duty config, then print every setting as key=value.
# Usage: bash config.sh [FILE]      (default .github/githard.yml)
# Format: flat "key: value" lines, "#" comments, lists written inline as [a, b].
# Stdout: one key=value line per key. Stderr: "warning  ..." for risky values, "invalid  key: why" on failure.
# Exit: 0 ok, 2 invalid or missing file. Never a default that acts: identity and monthly_cap_usd are required.
# shellcheck disable=SC2154 # the v_ variables are set through put()
set -uo pipefail
file=${1:-.github/githard.yml}
[ -f "$file" ] || { echo "invalid  file: $file not found" >&2; exit 2; }

KEYS="mode chat approve_first_count identity risky_paths_need_human wait_for_checks approvers monthly_cap_usd first_timer_runs_per_day release_after_days"
# Plain variables, not associative arrays: macOS ships bash 3.2.
put() { printf -v "v_$1" %s "$2"; }
for d in mode=safe chat=approve-first approve_first_count=5 risky_paths_need_human=true wait_for_checks= approvers= \
  first_timer_runs_per_day=none release_after_days=7; do put "${d%%=*}" "${d#*=}"; done
seen=" "
bad=0
invalid() { echo "invalid  $1: $2" >&2; bad=1; }

# Lists come out comma-joined. shortcut: items can't contain commas or brackets; fine for logins and check names.
list() {
  local raw=$1 key=$2 item out=""
  [[ $raw =~ ^\[(.*)\]$ ]] || { invalid "$key" "write a list like [a, b]"; return; }
  IFS=, read -ra items <<<"${BASH_REMATCH[1]}"
  for item in "${items[@]:-}"; do
    item=${item#"${item%%[![:space:]]*}"}; item=${item%"${item##*[![:space:]]}"}
    [ -n "$item" ] || continue
    if [ "$key" = approvers ] && ! [[ $item =~ ^[A-Za-z0-9-]+$ ]]; then invalid "$key" "\"$item\" isn't a GitHub login"; return; fi
    [[ $item =~ [[:space:]] ]] && { invalid "$key" "\"$item\" has a space; separate items with commas"; return; }
    out+="${out:+,}$item"
  done
  put "$key" "$out"
}

while IFS= read -r line || [ -n "$line" ]; do
  line=${line%%#*}
  line=${line#"${line%%[![:space:]]*}"}; line=${line%"${line##*[![:space:]]}"}
  [ -z "$line" ] && continue
  [[ $line =~ ^([a-z_]+):[[:space:]]*(.*)$ ]] || { invalid "$line" "expected key: value"; continue; }
  key=${BASH_REMATCH[1]}; val=${BASH_REMATCH[2]}
  [[ " $KEYS " == *" $key "* ]] || { invalid "$key" "unknown setting"; continue; }
  [[ $seen == *" $key "* ]] && { invalid "$key" "set twice"; continue; }
  seen+="$key "
  case $key in
    mode) [[ $val =~ ^(auto|safe)$ ]] || invalid mode "use auto or safe"; put mode "$val" ;;
    chat) [[ $val =~ ^(auto|approve|approve-first)$ ]] || invalid chat "use auto, approve or approve-first"; put chat "$val" ;;
    approve_first_count) [[ $val =~ ^[0-9]+$ && $val -ge 1 ]] || invalid approve_first_count "use a whole number, 1 or more"; put approve_first_count "$val" ;;
    identity) [[ $val =~ ^(maintainer|bot)$ ]] || invalid identity "use maintainer or bot"; put identity "$val" ;;
    risky_paths_need_human) [[ $val =~ ^(true|false)$ ]] || invalid risky_paths_need_human "use true or false"; put risky_paths_need_human "$val" ;;
    wait_for_checks|approvers) list "$val" "$key" ;;
    monthly_cap_usd) [[ $val == none || ( $val =~ ^[0-9]+(\.[0-9]+)?$ && $val =~ [1-9] ) ]] || invalid monthly_cap_usd "use a number above 0, or none"; put monthly_cap_usd "$val" ;;
    first_timer_runs_per_day) [[ $val == none || $val =~ ^[0-9]+$ ]] || invalid first_timer_runs_per_day "use a whole number, or none"; put first_timer_runs_per_day "$val" ;;
    release_after_days) [[ $val =~ ^[0-9]+$ && $val -ge 1 ]] || invalid release_after_days "use a whole number, 1 or more"; put release_after_days "$val" ;;
  esac
done < "$file"

for key in identity monthly_cap_usd; do
  [[ $seen == *" $key "* ]] || invalid "$key" "required, and setup hasn't filled it in"
done
[ $bad = 0 ] || exit 2

[ "$v_mode" = auto ] && echo "warning  mode is auto: the bot can merge pull requests and reply to people without asking you first." >&2
[ "$v_risky_paths_need_human" = false ] && echo "warning  risky_paths_need_human is false: the bot can now merge changes to .github/, build and release scripts and dependency files without a human looking." >&2
[ "$v_monthly_cap_usd" = none ] && echo "warning  monthly_cap_usd is none: anyone who can comment can start a run on your Claude account, and nothing stops the bill." >&2

for key in $KEYS; do vn=v_$key; echo "$key=${!vn:-}"; done
exit 0
