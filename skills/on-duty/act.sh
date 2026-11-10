#!/usr/bin/env bash
# Carry out the model's proposals through the gate, and carry out the cards a human approved.
# Usage: bash act.sh OWNER/REPO CFG ACTIONS_JSON [--dry-run --paths-from DIR [--review-required BOOL]]
#        bash act.sh OWNER/REPO CFG --approved [--dry-run --paths-from DIR]
#        bash act.sh OWNER/REPO CFG --release-due      (git only: exit 0 due, 1 not due, 2 unknown)
# ACTIONS_JSON is {"actions": [...]} written by the model. All of it is untrusted: every field is
# checked, and every fact (heads, changed files, review rules, labels, versions) is fetched here.
# Prints "done KIND TARGET", "queued KIND TARGET ID", "withdrawn KIND TARGET" or "refused KIND TARGET why".
# Exit 0 all done or queued, 1 something refused or failed, 2 bad command line or unreadable input.
# --dry-run never calls gh. It reads facts from DIR: <pr>.txt (changed files), heads.txt ("pr sha"
# lines), labels.txt, workflows/ (stands in for .github/workflows), queue.txt (queue issue number),
# queue-comments.txt (its comment ids), comments.json ([{id, user, body}] for comments reacted to),
# queue-comments.json (for --approved, as queue.sh parse reads it, plus last_edited_by), bot.txt and
# replies-approved.txt. It writes DIR/posted-<target>.txt and DIR/card-<kind>-<target>.txt, and skips verify-release.sh.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd); skills=$(dirname "$here")
MAX=20 # proposals per run; a steered model shouldn't get to spam
usage() { sed -n '2,14p' "$0" >&2; exit 2; }
[ $# -ge 3 ] || usage
repo=$1; cfg=$2; sub=$3; shift 3
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] && [ -f "$cfg" ] || usage
dry=""; dir=""; review=""
while [ $# -gt 0 ]; do
  case $1 in
    --dry-run) dry=1; shift ;;
    --paths-from|--review-required) [ $# -ge 2 ] || usage; [ "$1" = --paths-from ] && dir=$2 || review=$2; shift 2 ;;
    *) usage ;;
  esac
done
# facts come from DIR only in a dry run, and a dry run needs DIR
if [ -n "$dry" ]; then [ -d "$dir" ] || usage; else [ -z "$dir$review" ] || usage; fi
get() { grep "^$1=" "$cfg" | head -1 | cut -d= -f2-; }
tmp=$(mktemp -d) || exit 2; trap 'rm -rf "$tmp"' EXIT
rd() { [ -f "$dir/$1" ] && cat "$dir/$1"; }
clean() { printf '%s' "${1:--}" | tr -c 'A-Za-z0-9._-' '_' | cut -c1-40; }
ex() { # stdout is the report, so a command's output goes to stderr, with workflow commands defused
  [ -n "$dry" ] && return 0
  local rc=0; "$@" > "$tmp/out" 2>&1 || rc=$?; sed 's/^::/: :/' "$tmp/out" >&2; return $rc
}

# --- release facts, from git: sets version and breaking; returns 0 due, 1 not due, 2 unknown
release_facts() {
  local days last c oldest="" nv="$skills/releases/next-version.sh"
  days=$(get release_after_days); [[ $days =~ ^[0-9]+$ ]] || return 2
  last=$(git describe --tags --abbrev=0 2>/dev/null) || return 2
  version=$(git log --format='%s%n%b' "$last..HEAD" | bash "$nv" "$last") || return 2
  [ "$version" != none ] || return 1
  breaking=false; [[ $version == "breaking "* ]] && { breaking=true; version=${version#breaking }; }
  for c in $(git rev-list "$last..HEAD"); do # newest first, so the last hit is the oldest
    [ "$(git log -1 --format='%s%n%b' "$c" | bash "$nv" "$last")" = none ] || oldest=$(git log -1 --format=%ct "$c")
  done
  [[ $oldest =~ ^[0-9]+$ ]] || return 2
  [ $(( $(date +%s) - oldest )) -ge $(( days * 86400 )) ]
}
if [ "$sub" = --release-due ]; then release_facts; exit $?; fi

# --- identity and the queue issue, needed by both modes
if [ -n "$dry" ]; then bot=$(rd bot.txt); else bot=$(gh api user --jq .login); fi
[[ $bot =~ ^[A-Za-z0-9-]+(\[bot\])?$ ]] || { echo "act.sh: cannot tell who the bot is" >&2; exit 2; }
find_queue() {
  if [ -n "$dry" ]; then qnum=$(rd queue.txt | tr -d '[:space:]'); return 0; fi
  # the list API, not search, which lags behind a newly created issue; the oldest one is the queue
  qnum=$(gh api --paginate "repos/$repo/issues?state=open&labels=githard&per_page=100" --jq ".[] | select(.pull_request == null and .title == \"Waiting for you\"
    and (.user.login|ascii_downcase) == \"$(printf '%s' "$bot" | tr '[:upper:]' '[:lower:]')\") | .number" | sort -n | head -1) ||
    { echo "act.sh: couldn't look for the queue issue" >&2; exit 2; }
  [[ -z $qnum || $qnum =~ ^[1-9][0-9]*$ ]] || exit 2
}
find_queue

# --- facts about a PR; each fails (non-zero, nothing printed) when GitHub doesn't answer
pr_head() {
  if [ -n "$dry" ]; then rd heads.txt | awk -v n="$1" '$1 == n {print $2}' | grep -E '^[0-9a-f]+$'; return; fi
  local pull; pull=$(gh api "repos/$repo/pulls/$1") || return 1
  # only into the default branch: a PR aimed at an unprotected branch would dodge the ruleset
  [ "$(jq -r .base.ref <<<"$pull")" = "$(gh api "repos/$repo" --jq .default_branch)" ] || return 1
  jq -r 'select(.state == "open") | .head.sha' <<<"$pull" | grep -E '^[0-9a-f]{40}$'
}
pr_paths() { # writes PR $1's changed files at pinned head $2, renames' old names too, to $3; nothing on failure
  : > "$3"
  if [ -n "$dry" ]; then [ -f "$dir/$1.txt" ] && cp "$dir/$1.txt" "$3"; return 0; fi
  local n rows base
  read -r n base < <(gh api "repos/$repo/pulls/$1" --jq '"\(.changed_files) \(.base.ref)"') || return 0
  # keyed by the pinned commit, so a push after the head was read can't swap the list
  rows=$(gh api --paginate "repos/$repo/compare/$base...$2" --jq '.files[]? | "\(.filename)\t\(.previous_filename // "")"') || return 0
  # GitHub stops listing at 3000 files; a short list must not pass as the whole list
  [ "$(printf '%s\n' "$rows" | wc -l | tr -d ' ')" = "$n" ] || return 0
  printf '%s\n' "$rows" | tr '\t' '\n' | sed '/^$/d' > "$3"
}
review_rule() { # rulesets only: classic branch protection isn't read here, but gh pr merge still enforces it
  if [ -n "$dry" ]; then printf '%s' "$review"; return; fi
  local base; base=$(gh api "repos/$repo/pulls/$1" --jq .base.ref) || return 1
  gh api "repos/$repo/rules/branches/$base" --jq '[.[] | select(.type == "pull_request") | .parameters.required_approving_review_count] | (max // 0) > 0'
}
labels_known() {
  [ -f "$tmp/labels" ] || { if [ -n "$dry" ]; then rd labels.txt; else gh label list -R "$repo" --limit 1000 --json name --jq '.[].name'; fi; } > "$tmp/labels" || return 1
  cat "$tmp/labels"
}
queue_comment() { # could a reaction on comment $1 approve a card? errs on the side of yes
  local c b; b=$(printf '%s' "$bot" | tr '[:upper:]' '[:lower:]')
  if [ -n "$dry" ]; then
    [ -n "$qnum" ] && rd queue-comments.txt | grep -qx "$1" && return 0
    c=$(jq -c --argjson id "$1" '.[] | select(.id == $id) | {issue_url: "", user: {login: .user}, body}' "$dir/comments.json" 2>/dev/null)
    [ -n "$c" ] || return 1
  else c=$(gh api "repos/$repo/issues/comments/$1") || return 0; fi
  # the bot's own comments and anything card-shaped are off limits, queue issue known or not
  local rc=0; jq -e --arg b "$b" --arg q "/issues/${qnum:-none}" '(.user.login|ascii_downcase) == $b
    or (.body|startswith("<!-- githard-card")) or (.issue_url|endswith($q))' <<<"$c" >/dev/null || rc=$?
  [ $rc != 1 ] # 0 is yes, 1 is no, anything else is unreadable, so yes
}
in_workflows() { # does label $1 appear in a workflow? a missing folder counts as yes
  local w=.github/workflows; [ -n "$dry" ] && w=$dir/workflows
  [ -d "$w" ] || return 0
  grep -rqiwF -- "$1" "$w"
}
replies_approved() { if [ -n "$dry" ]; then rd replies-approved.txt; else gh variable get GITHARD_REPLIES_APPROVED -R "$repo" 2>/dev/null; fi; }

# --- validate $act (one action as JSON). Sets kind target cid login content tag labels body title why key.
# On refusal sets reason and returns 1. Nothing from the model is trusted past this point unchecked.
str() { jq -r --arg k "$1" 'if type == "object" then .[$k] else null end | if type == "string" or type == "number" then tostring else empty end' <<<"$act"; }
validate() {
  kind=$(str kind); target=$(str target); cid=$(str comment_id); key=""; reason=""
  login=$(str login); content=$(str content); tag=$(str tag); body=$(str body); title=$(str title); why=$(str why)
  case $kind in reply|react|assign|label|merge|close|approve-runs|release|publish|ask) ;; *) reason="unknown kind"; return 1 ;; esac
  jq -e '[.. | strings | select(contains("<!-- githard") or contains("<!-- /githard"))] | length == 0' <<<"$act" >/dev/null ||
    { reason="text carries a githard marker"; return 1; }
  # a card's footer says /approve ID, so model text that says it could pass for a real footer
  jq -e '[.. | strings | select(test("/approve [0-9a-f]{8}"; "i"))] | length == 0' <<<"$act" >/dev/null ||
    { reason="text says /approve and a card ID"; return 1; }
  digits() { jq -e --arg k "$1" '.[$k] | (type == "number" and . == floor and . > 0) or (type == "string" and test("^[0-9]+$"))' <<<"$act" >/dev/null; }
  case $kind in
    react) digits comment_id || { reason="comment_id must be digits"; return 1; }; key=$cid ;;
    release|publish|ask) key=0 ;;
    *) digits target || { reason="target must be digits"; return 1; }; key=$target ;;
  esac
  # canonical numbers only: "05" must not slip past the queue-issue check for #5
  case $kind in release|publish|ask) ;; *) [[ $key =~ ^[1-9][0-9]{0,17}$ ]] || { reason="target must be a plain number"; return 1; } ;; esac
  [ "$key" = 0 ] || [ "$key" != "$qnum" ] || [ "$kind" = react ] || { reason="that's the Waiting for you issue"; return 1; }
  case $kind in
    react) [[ " +1 rocket eyes hooray heart " == *" $content "* ]] || { reason="reaction not allowed"; return 1; }
      ! queue_comment "$cid" || { reason="that comment is in the Waiting for you issue"; return 1; } ;;
    assign) [[ $login =~ ^[A-Za-z0-9-]{1,39}$ ]] || { reason="not a GitHub login"; return 1; } ;;
    label) labels=$(jq -r '.labels | if type == "array" and length > 0 and all(type == "string") then .[] else error end' <<<"$act" 2>/dev/null) ||
        { reason="labels must be a list of names"; return 1; }
      labels_known > "$tmp/known" || { reason="couldn't read the repo's labels"; return 1; }
      while IFS= read -r l; do grep -qxF -- "$l" "$tmp/known" || { reason="label doesn't exist in the repo"; return 1; }
        ! in_workflows "$l" || { reason="a workflow reacts to that label"; return 1; }; done <<<"$labels" ;;
    reply|close) [ -n "$body" ] && [ ${#body} -le 60000 ] || { reason="body is empty or too long"; return 1; } ;;
    publish) [[ $tag =~ ^([A-Za-z0-9-]+--)?v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { reason="not a version tag"; return 1; } ;;
    ask) [ -n "$title" ] && [ -n "$body" ] || { reason="ask needs a title and a body"; return 1; } ;;
  esac
}

# --- fetch the facts the gate and the action need. Sets head, version, gate args (g). Returns 1 with reason.
facts() {
  head=-; g=()
  case $kind in
    merge|approve-runs)
      head=$(pr_head "$key") || { reason="couldn't read an open PR into the default branch"; return 1; } ;;
  esac
  case $kind in
    merge) pr_paths "$key" "$head" "$tmp/paths"; g=(--paths "$tmp/paths")
      local r; r=$(review_rule "$key") && [[ $r =~ ^(true|false)$ ]] && g+=(--review-required "$r") ;;
    reply|react|assign) local n; n=$(replies_approved) && [[ $n =~ ^[0-9]+$ ]] && g=(--replies-approved "$n") ;;
    release) local rc=0; release_facts || rc=$?
      [ $rc = 0 ] || { [ $rc = 1 ] && reason="no release due yet" || reason="couldn't work out the release"; return 1; }
      g=(--breaking "$breaking") ;;
    publish) [ -n "$dry" ] || bash "$skills/releases/verify-release.sh" "$repo" "$tag" >&2 || { reason="verify-release.sh failed on $tag"; return 1; } ;;
  esac
  return 0 # a missing optional fact only leaves the gate to queue
}

post() { # comment $body on #$1, marked as ours
  printf '%s\n\n<!-- githard -->\n' "$body" > "$tmp/body"
  if [ -n "$dry" ]; then cp "$tmp/body" "$dir/posted-$1.txt"; return 0; fi
  gh api -X POST "repos/$repo/issues/$1/comments" -F "body=@$tmp/body" >/dev/null
}
execute() {
  local a=() c checks=()
  case $kind in
    reply) post "$key" ;;
    close) post "$key" && ex gh api -X PATCH "repos/$repo/issues/$key" -f state=closed ;;
    react) ex gh api -X POST "repos/$repo/issues/comments/$key/reactions" -f "content=$content" ;;
    assign) ex gh api -X POST "repos/$repo/issues/$key/assignees" -f "assignees[]=$login" ;;
    label) while IFS= read -r c; do a+=(-f "labels[]=$c"); done <<<"$labels"
      ex gh api -X POST "repos/$repo/issues/$key/labels" "${a[@]}" ;;
    merge) IFS=, read -ra checks <<<"$(get wait_for_checks)"
      for c in ${checks[@]+"${checks[@]}"}; do a+=(--require "$c"); done
      ex bash "$skills/merging/merge-when-green.sh" "$repo" "$key" --head "$head" --timeout-min 20 ${a[@]+"${a[@]}"} ;;
    approve-runs) ex bash "$skills/fork-pr-safety/approve-runs.sh" "$repo" "$key" ;;
    release) ex gh workflow run release.yml -R "$repo" -f "version=${version##*v}" ;; # builds a draft, never publishes
    publish) ex gh release edit "$tag" -R "$repo" --draft=false ;;
    ask) : ;;
  esac
}
shown() { case $kind in release) echo "${version:--}" ;; publish) echo "$tag" ;; ask) echo - ;; *) echo "$key" ;; esac; }

fenced() { # model text on a card renders as inert code: the fence is longer than any backtick run inside
  local n f='```'; n=$(printf '%s' "$1" | grep -oE '`+' | awk '{ if (length($0) > m) m = length($0) } END { print m + 0 }')
  while [ ${#f} -le "$n" ]; do f+='`'; done
  printf '%s\n%s\n%s\n\n' "$f" "$1" "$f"
}
queue_card() { # posts a card for the current action; prints its ID
  local line
  case $kind in
    reply) line="Reply on #$key" ;; close) line="Close #$key with this comment" ;; merge) line="Merge #$key at ${head:0:7}" ;;
    react) line="React $content to comment $key" ;; assign) line="Assign #$key to @$login" ;;
    approve-runs) line="Approve the waiting CI runs on #$key at ${head:0:7}" ;;
    release) line="Release $version (a draft, for you to publish)" ;; publish) line="Publish the $tag release" ;;
    *) line="$kind #$key" ;;
  esac
  [ "$kind" = ask ] && line="Question"
  { printf '**%s**\n\n' "$line"
    fenced "$why"; [ "$kind" = ask ] && fenced "$title"$'\n\n'"$body"
    # < and > only occur inside JSON strings, so escaping them keeps valid JSON that can't close the comment
    printf '<!-- githard-action %s -->\n' "$(jq -c --arg v "${version:-}" 'del(.body) | if .kind == "release" then .version = $v else . end' <<<"$act" |
      sed 's/</\\u003c/g; s/>/\\u003e/g')"
    case $kind in reply|close) fenced "<!-- githard-draft -->"$'\n'"$body"$'\n'"<!-- /githard-draft -->" ;; esac
  } > "$tmp/card"
  if [ -n "$dry" ]; then cp "$tmp/card" "$dir/card-$kind-$key.txt"; echo dry-run; return 0; fi
  bash "$here/queue.sh" add "$repo" "$kind" "$key" "$head" "$tmp/card" | grep -E '^[0-9a-f]{8}$'
}

# --- proposals
if [ "$sub" != --approved ]; then
  [[ $sub != -* && -f $sub ]] || usage
  jq -e '.actions | type == "array"' "$sub" >/dev/null 2>&1 || { echo "act.sh: $sub has no actions list" >&2; exit 2; }
  out=0; i=0
  while IFS= read -r act; do
    i=$((i + 1)); version=""
    if [ $i -gt $MAX ]; then kind=$(str kind); echo "refused $(clean "$kind") - over $MAX proposals in one run"; out=1; continue; fi
    if ! validate || ! facts; then echo "refused $(clean "$kind") $(clean "${key:-$target$cid$tag}") $reason"; out=1; continue; fi
    verdict=$(bash "$here/gate.sh" decide "$cfg" "$kind" ${g[@]+"${g[@]}"} 2>/dev/null) || verdict=""
    if [ "$verdict" = go ]; then
      if execute; then echo "done $kind $(shown)"; else echo "refused $kind $(shown) GitHub said no"; out=1; fi
    elif id=$(queue_card); then echo "queued $kind $(shown) $id"; [ -n "$qnum" ] || find_queue
    else echo "refused $kind $(shown) couldn't post the card"; out=1; fi
  done < <(jq -c '.actions[]' "$sub")
  exit $out
fi

# --- approved cards: no model here, only the card text a human saw and approved
[ -n "$qnum" ] || exit 0
mark() { [ -n "$dry" ] || bash "$here/queue.sh" "done" "$repo" "$1" "$2" >/dev/null || echo "act.sh: couldn't mark card $1 done" >&2; }
CARD='^<!-- githard-card id=[0-9a-f]{8} kind=[a-z-]+ target=(?<t>[0-9]+) head=[0-9a-f]+ -->'
if [ -n "$dry" ]; then
  cp "$dir/queue-comments.json" "$tmp/comments" && cp "$dir/heads.txt" "$tmp/heads" || exit 2
  approvers="${repo%%/*},$(get approvers)"
else
  gh api --paginate --slurp "repos/$repo/issues/$qnum/comments" |
    jq '[.[][] | {id, node_id, user: .user.login, body, plus: (.reactions["+1"] // 0)}]' > "$tmp/c0" || exit 2
  jq 'map(del(.node_id))' "$tmp/c0" > "$tmp/comments"
  for id in $(jq -r '.[] | select(.plus > 0 and (.body | startswith("<!-- githard-card "))) | .id' "$tmp/c0"); do
    who=$(gh api --paginate -X GET "repos/$repo/issues/comments/$id/reactions" -f content=+1 --jq '[.[].user.login]' | jq -s 'add // []') || who='[]'
    jq --argjson id "$id" --argjson w "$who" 'map(if .id == $id then .plus_one_by = $w else . end)' "$tmp/comments" > "$tmp/c1" && mv "$tmp/c1" "$tmp/comments"
  done
  : > "$tmp/heads"
  for t in $(jq -r --arg re "$CARD" '.[].body | capture($re)? | .t' "$tmp/comments" | sort -u); do
    h=$(pr_head "$t") && echo "$t $h" >> "$tmp/heads"
  done
  approvers="${repo%%/*},$(get approvers)"
  for p in admin maintain; do
    approvers+=",$(gh api --paginate "repos/$repo/collaborators?permission=$p" --jq '.[].login' 2>/dev/null | paste -sd, -)"
  done
fi
bash "$here/queue.sh" parse --approvers "$approvers" --bot "$bot" --heads "$tmp/heads" < "$tmp/comments" > "$tmp/parsed" || exit 2
out=0
while read -r state _ ckind ctarget comment; do
  if [ "$state" = stale ]; then mark "$comment" "Withdrawn: the PR changed since this card was written."; echo "withdrawn $ckind $ctarget"; continue; fi
  # an edit by someone who can't approve voids the approval; an unknown editor counts as that
  if [ -n "$dry" ]; then editor=$(jq -r --argjson id "$comment" '.[] | select(.id == $id) | .last_edited_by // ""' "$tmp/comments")
  else editor=$(gh api graphql -f query='query($id: ID!) { node(id: $id) { ... on IssueComment { lastEditedBy { login } } } }' \
      -f id="$(jq -r --argjson id "$comment" '.[] | select(.id == $id) | .node_id' "$tmp/c0")" |
      jq -er '.data.node | if . == null then error else (.lastEditedBy.login // "") end') || editor="?"; fi
  e=$(printf '%s' "$editor" | tr '[:upper:]' '[:lower:]')
  if [ -n "$e" ] && [[ ",$(printf '%s' "$bot,$approvers" | tr '[:upper:]' '[:lower:]')," != *",$e,"* ]]; then
    mark "$comment" "Withdrawn: someone who can't approve edited this card."; echo "withdrawn $ckind $ctarget"; continue
  fi
  # an ask is the owner's own decision, so there's nothing to carry out: a thumbs up just files it
  if [ "$ckind" = ask ]; then mark "$comment" "Done: noted."; echo "done ask -"; continue; fi
  text=$(jq -r --argjson id "$comment" '.[] | select(.id == $id) | .body' "$tmp/comments")
  act=$(printf '%s\n' "$text" | sed -n 's/^<!-- githard-action \(.*\) -->$/\1/p' | head -1)
  if [[ $ckind == reply || $ckind == close ]]; then # the card's current draft, so a maintainer's edit is what goes out
    draft=$(printf '%s\n' "$text" | awk '/^<!-- \/githard-draft -->$/ {f=0} f {print} /^<!-- githard-draft -->$/ && !s {f=1; s=1}')
    act=$(jq -c --arg b "$draft" '.body = $b' <<<"$act" 2>/dev/null)
  fi
  version=""; reason=""; want=$(jq -r '.version // empty' <<<"$act" 2>/dev/null)
  chead=$(printf '%s\n' "$text" | sed -n '1s/^.* head=\([0-9a-f-]*\) -->.*$/\1/p')
  # act on exactly what the human saw: same PR head, same release version
  if ! jq -e . <<<"$act" >/dev/null 2>&1 || ! validate || [ "$kind" != "$ckind" ] || [ "$key" != "$ctarget" ] || ! facts ||
    { [ "$head" != - ] && [ "$head" != "$chead" ]; } || { [ "$kind" = release ] && [ "$version" != "$want" ]; }; then
    reason=${reason:-the card no longer matches}; mark "$comment" "Not done: $reason."
    echo "refused $ckind $ctarget $reason"; out=1; continue
  fi
  if execute; then
    mark "$comment" "Done."; echo "done $kind $(shown)"
    if [ "$kind" = reply ] && [ -z "$dry" ]; then
      n=$(replies_approved); [[ $n =~ ^[0-9]+$ ]] || n=0
      gh variable set GITHARD_REPLIES_APPROVED -R "$repo" --body "$((n + 1))" >/dev/null || echo "act.sh: couldn't count the approved reply" >&2
    fi
  else mark "$comment" "Failed: GitHub said no. Propose it again if it still matters."; echo "refused $kind $(shown) GitHub said no"; out=1; fi
done < "$tmp/parsed"
exit $out
