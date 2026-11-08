#!/usr/bin/env bash
# Find claims in docs that aren't true of the released version.
# Usage: bash audit-docs.sh DOCS_PATH [--tool NAME --help-cmd "CMD"] [--no-links]
#   Links: every http(s) URL in DOCS_PATH must answer below 400. A URL that doesn't answer at all
#          is "unknown", not dead.
#   Flags: with --tool and --help-cmd, each `NAME subcommand` and `--flag` in a code block must
#          appear in the help text CMD prints. Run CMD against the released build, not main.
# Prints one line per untrue claim as path:line. Exits 1 if it found any.
set -uo pipefail
docs=${1:?usage: bash audit-docs.sh DOCS_PATH [--tool NAME --help-cmd CMD] [--no-links]}
shift; tool=""; help_cmd=""; links=1
while [ $# -gt 0 ]; do
  case $1 in --tool) tool=$2; shift 2 ;; --help-cmd) help_cmd=$2; shift 2 ;; --no-links) links=0; shift ;; *) echo "unknown option $1"; exit 2 ;; esac
done
files=$(grep -rlE . "$docs" --include='*.md' --include='*.mdx' 2>/dev/null; [ -f "$docs" ] && echo "$docs")
[ -n "$files" ] || { echo "no Markdown found in $docs"; exit 2; }
status=0

if [ $links = 1 ]; then
  found=$(grep -noE 'https?://[^] )"'"'"'<>`]+' $files /dev/null | sed -E 's/[.,;:]+$//' | sort -t: -k3 -u |
  while IFS= read -r hit; do
    where=${hit%%:http*}; url=${hit#"$where":}
    code=$(curl -sIL -o /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null)
    # Some servers refuse HEAD; ask again with GET before calling a link dead.
    [ "$code" -ge 400 ] 2>/dev/null && code=$(curl -sL -o /dev/null -w '%{http_code}' --max-time 10 "$url" 2>/dev/null)
    case $code in (000) echo "unknown  $where  $url (no answer)" ;; ([45]??) echo "dead     $where  $url ($code)" ;; esac
  done)
  [ -n "$found" ] && echo "$found"
  grep -q '^dead' <<<"$found" && status=1
fi

if [ -n "$tool" ] && [ -n "$help_cmd" ]; then
  help=$(bash -c "$help_cmd" 2>&1) || { echo "unknown  --help-cmd failed: $help_cmd"; exit 2; }
  # Lines inside fenced code blocks that run the tool, with their file and line number.
  runs=$(awk -v t="$tool" 'FNR==1{fence=0} /^```/{fence=!fence; next}
    fence { line=$0; sub(/^[$>] */,"",line); if (index(line, t" ")==1) print FILENAME":"FNR":"line }' $files)
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    where=$(cut -d: -f1,2 <<<"$hit"); cmd=$(cut -d: -f3- <<<"$hit")
    sub=$(awk '{print $2}' <<<"$cmd")
    if [ -n "$sub" ] && [[ $sub != -* ]] && ! grep -qwF -- "$sub" <<<"$help"; then
      echo "untrue   $where  \`$tool $sub\` isn't in the help text"; status=1
    fi
    for flag in $(grep -oE -- '--[a-z][a-z0-9-]*' <<<"$cmd" | sort -u); do
      grep -qF -- "$flag" <<<"$help" || { echo "untrue   $where  \`$flag\` isn't in the help text"; status=1; }
    done
  done <<<"$runs"
fi
exit $status
