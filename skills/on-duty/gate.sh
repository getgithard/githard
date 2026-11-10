#!/usr/bin/env bash
# Decide whether a proposed action goes out or waits for a human. The model never decides this.
# Usage: bash gate.sh decide CFG KIND [--paths FILE] [--review-required true|false] [--breaking true|false]
#                           [--replies-approved N] [--labeled-trigger true|false]
#        bash gate.sh should-run CFG --assoc ASSOC --body-file FILE --runs-today N
# CFG is the output of config.sh saved to a file. --paths lists one changed file per line (merge, approve-runs).
# --labeled-trigger says whether any workflow runs when a label is added: then a label is a privileged act.
# Stdout: decide prints "go" or "queue <reason>"; should-run prints "run" or "skip <reason>". Exit 0.
# Exit 2 on a bad command line. Anything missing, garbled or unknown queues or skips, never goes.
set -uo pipefail

RISKY='^\.github/|(^|/)(Makefile|GNUmakefile|makefile|Dockerfile|Containerfile|justfile|setup\.py|[^/]*\.gemspec|build\.[a-z]+|release[^/]*\.(sh|ya?ml))$|^scripts/|(^|/)(package(-lock)?\.json|bun\.lockb?|yarn\.lock|pnpm-lock\.yaml|go\.(mod|sum)|Cargo\.(toml|lock)|requirements[^/]*\.txt|pyproject\.toml|poetry\.lock|uv\.lock|Gemfile(\.lock)?|composer\.(json|lock))$'

sub=${1:-}; cfg=${2:-}
[ $# -ge 2 ] || { echo "usage: gate.sh decide|should-run CFG ..." >&2; exit 2; }
shift 2
case $sub in decide|should-run) ;; *) echo "usage: gate.sh decide|should-run CFG ..." >&2; exit 2 ;; esac

if [ "$sub" = decide ]; then no() { echo "queue $1"; exit 0; }; else no() { echo "skip $1"; exit 0; }; fi
[ -f "$cfg" ] || no "no config"
get() { grep "^$1=" "$cfg" | head -1 | cut -d= -f2-; }

if [ "$sub" = decide ]; then
  kind=${1:-}; shift || no "no kind"
  paths=""; review=""; breaking=""; approved=""; labeled=""
  while [ $# -gt 0 ]; do
    [ $# -ge 2 ] || no "flag $1 has no value"
    case $1 in
      --paths) paths=$2 ;; --review-required) review=$2 ;; --breaking) breaking=$2 ;; --replies-approved) approved=$2 ;; --labeled-trigger) labeled=$2 ;;
      *) no "unknown flag $1" ;;
    esac
    shift 2
  done
  mode=$(get mode); chat=$(get chat); count=$(get approve_first_count); risky=$(get risky_paths_need_human)
  [[ $mode =~ ^(auto|safe)$ ]] || no "config mode is missing or invalid"
  [[ $chat =~ ^(auto|approve|approve-first)$ ]] || no "config chat is missing or invalid"
  [[ $count =~ ^[0-9]+$ ]] || no "config approve_first_count is missing or invalid"
  [[ $risky =~ ^(true|false)$ ]] || no "config risky_paths_need_human is missing or invalid"
  by_mode() { [ "$mode" = auto ] && echo go || no "safe mode"; }
  case $kind in
    ask|settings) no "$kind always waits for a human" ;;
    label) if [ "$labeled" = false ]; then echo go; else by_mode; fi ;;
    reply|react|assign)
      if [ "$mode" = auto ] || [ "$chat" = auto ]; then echo go
      elif [ "$chat" = approve ]; then no "chat needs approval"
      elif [[ $approved =~ ^[0-9]+$ ]] && [ "$approved" -ge "$count" ]; then echo go
      else no "approve-first: $count approved replies needed"; fi ;;
    merge|approve-runs) # approving fork CI runs the PR's code, so it gets the same path check as a merge
      if [ "$kind" = merge ]; then
        [[ $review =~ ^(true|false)$ ]] || no "review state unknown"
        [ "$review" = false ] || no "review required"
      fi
      if [ "$risky" = true ]; then
        grep -q . "$paths" 2>/dev/null || no "changed files unknown"
        grep -Eq "$RISKY" "$paths" && no "touches risky paths"
      fi
      by_mode ;;
    release|publish)
      [[ $breaking =~ ^(true|false)$ ]] || no "breaking state unknown"
      [ "$breaking" = false ] || no "breaking change"
      by_mode ;;
    close) by_mode ;;
    *) no "unknown kind" ;;
  esac
  exit 0
fi

assoc=""; body=""; runs=""
while [ $# -gt 0 ]; do
  [ $# -ge 2 ] || no "flag $1 has no value"
  case $1 in --assoc) assoc=$2 ;; --body-file) body=$2 ;; --runs-today) runs=$2 ;; *) no "unknown flag $1" ;; esac
  shift 2
done
[ -f "$body" ] || no "no body to read"
grep -qF '<!-- githard -->' "$body" && no "own comment"
limit=$(get first_timer_runs_per_day)
[[ $limit == none || $limit =~ ^[0-9]+$ ]] || no "config first_timer_runs_per_day is missing or invalid"
if [[ $limit =~ ^[0-9]+$ ]]; then
  [[ $runs =~ ^[0-9]+$ ]] || no "runs today unknown"
  case $assoc in
    OWNER|MEMBER|COLLABORATOR|CONTRIBUTOR) ;;
    *) [ "$runs" -lt "$limit" ] || no "first-timer daily limit reached" ;; # unknown or empty counts as a stranger
  esac
fi
echo run
