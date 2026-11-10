#!/usr/bin/env bash
# Keep on-duty inside the maintainer's monthly cap on Claude spend.
# Usage: bash spend.sh check STATE CAP MONTH
#        bash spend.sh add STATE COST MONTH
# STATE is "YYYY-MM AMOUNT" (the GITHARD_SPEND variable) or empty. CAP is a number above 0, or none.
# MONTH is YYYY-MM. COST is the Action's total_cost_usd.
# check prints ok or over. add prints the new state; a garbled STATE counts as 0, with a warning.
# Exit 0 ok, 2 bad input (nothing printed). Callers treat 2 as "don't run Claude".
set -uo pipefail

NUM='^[0-9]+(\.[0-9]+)?$'
MON='^[0-9]{4}-(0[1-9]|1[0-2])$'
bad() { echo "spend.sh: $1" >&2; exit 2; }

[ $# -eq 4 ] || bad "usage: spend.sh check|add STATE CAP|COST MONTH"
sub=$1; state=$2; arg=$3; month=$4
[[ $month =~ $MON ]] || bad "bad month: $month"

# Amount already spent this month, or "garbled".
spent=0
if [ -n "$state" ]; then
  if [[ $state =~ ^([0-9]{4}-[0-9]{2})\ ([0-9]+(\.[0-9]+)?)$ ]]; then
    [ "${BASH_REMATCH[1]}" = "$month" ] && spent=${BASH_REMATCH[2]}
  else
    spent=garbled
  fi
fi

case $sub in
  check)
    [ "$arg" = none ] || { [[ $arg =~ $NUM ]] && awk -v c="$arg" 'BEGIN { exit !(c > 0) }'; } || bad "bad cap: $arg"
    [ "$spent" != garbled ] || bad "bad state: $state"
    [ "$arg" = none ] && { echo ok; exit 0; }
    awk -v s="$spent" -v c="$arg" 'BEGIN { print (s + 0 >= c + 0) ? "over" : "ok" }'
    ;;
  add)
    [[ $arg =~ $NUM ]] || bad "bad cost: $arg"
    [ "$spent" != garbled ] || { echo "spend.sh: bad state '$state', counting it as 0" >&2; spent=0; }
    awk -v s="$spent" -v c="$arg" -v m="$month" 'BEGIN { printf "%s %.2f\n", m, s + c }'
    ;;
  *) bad "unknown command: $sub" ;;
esac
