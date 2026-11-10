#!/usr/bin/env bash
# The approval queue: cards in a pinned "Waiting for you" issue, approved by a maintainer.
# Usage: bash queue.sh parse --approvers a,b --bot LOGIN --heads FILE   (JSON on stdin)
#        bash queue.sh has --bot LOGIN KIND TARGET HEAD                 (JSON on stdin)
#        bash queue.sh add OWNER/REPO KIND TARGET HEAD BODY_FILE
#        bash queue.sh done OWNER/REPO COMMENT_ID RESULT
# stdin is a JSON array of {id, user, body, plus_one_by: [logins]}. All of it is untrusted.
# A card counts only when its user is --bot and its body is a marker line and ends with <!-- githard -->.
# An "ask" card carries the first 12 hex of the sha256 of its body as head, so each question is its own card.
# FILE holds "target sha" lines. A card head of "-" never goes stale; a missing target does.
# parse prints "approved|stale ID KIND TARGET COMMENT_ID". has prints the card ID.
# Exit 0 ok / 1 no match / 2 bad input or gh failure. Unknown never counts as approved.
set -uo pipefail

TITLE="Waiting for you"
MARK='<!-- githard -->'
DONE='<!-- githard-done -->'
usage() { sed -n '2,11p' "$0" >&2; exit 2; }

# open (not done) cards as JSON: {cid, kind, target, head, id}
CARDS='def cards($b): [ .[]
  | select(type == "object" and (.id|type) == "number" and (.user|type) == "string" and (.body|type) == "string")
  | select((.user|ascii_downcase) == $b and (.body|test("<!-- githard -->\\s*$")))
  | . as $c
  | ($c.body | capture("^<!-- githard-card id=(?<cid>[0-9a-f]{8}) kind=(?<kind>[a-z-]+) target=(?<target>[0-9]+) head=(?<head>[0-9a-f]+|-) -->(\\s|$)"))
  + {id: $c.id, done: ($c.body|contains("<!-- githard-done -->"))}
  | select(.done|not) ];'

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

parse() {
  local approvers="" bot="" heads=""
  while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || usage
    case $1 in --approvers) approvers=$2 ;; --bot) bot=$2 ;; --heads) heads=$2 ;; *) usage ;; esac
    shift 2
  done
  [ -n "$bot" ] && [ -f "$heads" ] || usage
  jq -r --arg a "$(lc "$approvers")" --arg b "$(lc "$bot")" --rawfile h "$heads" "$CARDS"'
    def trim: gsub("^\\s+|\\s+$"; "");
    ($a | split(",") | map(trim) | map(select(length > 0))) as $A
    | ($h | split("\n") | map(select(length > 0) | split(" ") | {key: .[0], value: .[1]}) | from_entries) as $H
    | . as $all
    | cards($b)[] as $k
    | ([ $all[] | select(type == "object" and (.user|type) == "string" and (.body|type) == "string" and (.id|type) == "number")
         | select(.id > $k.id and ((.user|ascii_downcase) as $u | $A | index($u)))
         | select((.body|trim|ascii_downcase) == "/approve " + $k.cid) ] | length > 0) as $said
    | ([ $all[] | select(.id == $k.id) | (.plus_one_by | if type == "array" then . else [] end)[]
         | select(type == "string") | ascii_downcase | select(. as $u | $A | index($u)) ] | length > 0) as $thumb
    | if $k.head != "-" and $k.kind != "ask" and ($H[$k.target] // "") != $k.head then "stale \($k.cid) \($k.kind) \($k.target) \($k.id)"
      elif $said or $thumb then "approved \($k.cid) \($k.kind) \($k.target) \($k.id)" else empty end
  ' 2>/dev/null
  [ "${PIPESTATUS[0]}" = 0 ] || { echo "queue.sh: stdin is not the expected JSON" >&2; return 2; }
}

has() {
  local bot=""
  [ "${1:-}" = --bot ] && [ $# -ge 2 ] || usage
  bot=$2; shift 2
  [ $# -eq 3 ] || usage
  local out rc=0
  out=$(jq -r --arg b "$(lc "$bot")" --arg k "$1" --arg t "$2" --arg h "$3" "$CARDS"'
    [ cards($b)[] | select(.kind == $k and .target == $t and .head == $h) | .cid ] | first // empty') || rc=2
  [ $rc = 0 ] || { echo "queue.sh: stdin is not the expected JSON" >&2; return 2; }
  [ -n "$out" ] && { echo "$out"; return 0; }
  return 1
}

body_hash() { # first 12 hex of the body's sha256
  local h
  if command -v sha256sum >/dev/null; then h=$(sha256sum < "$1"); else h=$(shasum -a 256 < "$1"); fi || return 1
  h=${h:0:12}; [[ $h =~ ^[0-9a-f]{12}$ ]] && echo "$h"
}

repo_ok() { [[ $1 =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; }

add() {
  [ $# -eq 5 ] || usage
  local repo=$1 kind=$2 target=$3 head=$4 body=$5 me num id tmp found comments
  repo_ok "$repo" && [[ $kind =~ ^[a-z-]+$ && $target =~ ^[0-9]+$ && $head =~ ^([0-9a-f]+|-)$ ]] && [ -f "$body" ] || usage
  me=$(gh api user --jq .login) && [ -n "$me" ] || { echo "queue.sh: cannot tell who the bot is" >&2; return 2; }
  # a stranger's issue with the same title must never become the queue
  num=$(gh issue list -R "$repo" --label githard --state open --search "\"$TITLE\" in:title" --json number,title,author \
    --jq "[.[] | select(.title == \"$TITLE\" and (.author.login|ascii_downcase) == (\"$(lc "$me")\"))] | first | .number // empty") || return 2
  if [ -z "$num" ]; then
    num=$(gh issue create -R "$repo" --title "$TITLE" --label githard \
      --body "Everything GitHard wants to do waits here. Give a card a thumbs up, or reply /approve and its ID. $MARK" | grep -o '[0-9]*$') || return 2
    gh issue pin "$num" -R "$repo" >/dev/null 2>&1 || echo "queue.sh: could not pin issue #$num" >&2
  fi
  [ -n "$num" ] || return 2
  [ "$kind" = ask ] && { head=$(body_hash "$body") || return 2; }
  # fetch first: a failed read must exit 2, not look like "no duplicate"
  comments=$(gh api --paginate --slurp "repos/$repo/issues/$num/comments") || return 2
  found=$(printf '%s' "$comments" | jq '[.[][] | {id, user: .user.login, body, plus_one_by: []}]' | bash "$0" has --bot "$me" "$kind" "$target" "$head")
  case $? in 0) echo "$found"; return 0 ;; 1) ;; *) return 2 ;; esac
  id=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
  tmp=$(mktemp) || return 2
  { printf '<!-- githard-card id=%s kind=%s target=%s head=%s -->\n' "$id" "$kind" "$target" "$head"
    cat "$body"; printf '\n%s\n' "$MARK"; } > "$tmp"
  gh api -X POST "repos/$repo/issues/$num/comments" -F "body=@$tmp" >/dev/null; local rc=$?
  rm -f "$tmp"
  [ $rc = 0 ] || return 2
  echo "$id"
}

done_() {
  [ $# -eq 3 ] || usage
  local repo=$1 cid=$2 result=$3 text tmp rc me json author
  repo_ok "$repo" && [[ $cid =~ ^[0-9]+$ ]] || usage
  me=$(gh api user --jq .login) && [ -n "$me" ] || { echo "queue.sh: cannot tell who the bot is" >&2; return 2; }
  json=$(gh api "repos/$repo/issues/comments/$cid") || return 2
  author=$(printf '%s' "$json" | jq -r '.user.login // empty') || return 2
  text=$(printf '%s' "$json" | jq -r '.body // empty') || return 2
  # only ever edit a card the bot wrote: author is the authenticated login, body is a card
  [ "$(lc "$author")" = "$(lc "$me")" ] && [[ $text == "<!-- githard-card "* ]] || { echo "queue.sh: comment $cid is not the bot's card" >&2; return 2; }
  [[ $text == *"$DONE"* ]] && return 0
  [[ $text =~ "$MARK"[[:space:]]*$ ]] || { echo "queue.sh: comment $cid is not an open card" >&2; return 2; }
  tmp=$(mktemp) || return 2
  printf '%s\n\n%s\n%s\n' "$text" "$DONE" "$(printf '%s' "$result" | tr '\r\n' '  ')" > "$tmp"
  gh api -X PATCH "repos/$repo/issues/comments/$cid" -F "body=@$tmp" >/dev/null; rc=$?
  rm -f "$tmp"
  [ $rc = 0 ] || return 2
}

sub=${1:-}; [ $# -ge 1 ] || usage; shift
case $sub in
  parse) parse "$@" ;;
  has) has "$@" ;;
  add) add "$@" ;;
  done) done_ "$@" ;;
  *) usage ;;
esac
