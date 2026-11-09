#!/usr/bin/env bash
# Check a site's HTTP hardening headers, for the gold criterion hardened_site.
# Usage: bash check-headers.sh URL [URL...]
# Each header must be present with a nonpermissive value:
#   Content-Security-Policy        no unsafe-inline or unsafe-eval in script-src (wasm-unsafe-eval is fine), and no * source
#   Strict-Transport-Security      max-age of at least 15552000 (180 days)
#   X-Content-Type-Options         nosniff
#   frame protection               X-Frame-Options DENY/SAMEORIGIN, or CSP frame-ancestors
#   Referrer-Policy is reported as a note: worth setting, but not one of the criterion's headers.
# Exits 1 if any URL misses one.
set -uo pipefail
[ $# -gt 0 ] || { echo "usage: bash check-headers.sh URL [URL...]"; exit 2; }
status=0
for url in "$@"; do
  # Keep only the last response's headers, after any redirects.
  h=$(curl -sIL --max-time 15 "$url" | tr -d '\r' | awk '/^HTTP\//{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}') ||
    { echo "unknown  $url (no answer)"; status=1; continue; }
  get() { grep -i "^$1:" <<<"$h" | head -1 | cut -d: -f2- | sed 's/^ *//'; }
  fail() { echo "missing  $url  $1"; status=1; }
  csp=$(get content-security-policy)
  if [ -z "$csp" ]; then fail "Content-Security-Policy"
  else
    script=$(tr ';' '\n' <<<"$csp" | grep -iE '^ *(script-src|default-src)' | head -1)
    # 'wasm-unsafe-eval' only allows WebAssembly, so it doesn't count as eval.
    sed "s/'wasm-unsafe-eval'//g" <<<"$script" | grep -qiE "unsafe-inline|unsafe-eval|(^| )\*( |$)" && fail "Content-Security-Policy allows inline, eval or any source for scripts: $script"
  fi
  hsts=$(get strict-transport-security); age=$(grep -oiE 'max-age=[0-9]+' <<<"$hsts" | cut -d= -f2)
  [ "${age:-0}" -ge 15552000 ] || fail "Strict-Transport-Security max-age of at least 180 days (got: ${hsts:-none})"
  [ "$(get x-content-type-options | tr '[:upper:]' '[:lower:]')" = nosniff ] || fail "X-Content-Type-Options: nosniff"
  xfo=$(get x-frame-options | tr '[:lower:]' '[:upper:]')
  [[ $xfo == DENY || $xfo == SAMEORIGIN ]] || grep -qi 'frame-ancestors' <<<"$csp" || fail "X-Frame-Options DENY or CSP frame-ancestors"
  rp=$(get referrer-policy | tr '[:upper:]' '[:lower:]')
  { [ -n "$rp" ] && [[ $rp != *unsafe-url* ]]; } || echo "note     $url  Referrer-Policy: consider strict-origin-when-cross-origin (got: ${rp:-none})"
done
[ $status = 0 ] && echo "ok       every URL sends hardened headers"
exit $status
