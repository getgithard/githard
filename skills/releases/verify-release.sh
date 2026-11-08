#!/usr/bin/env bash
# Check a draft release before anyone publishes it.
# Usage: bash verify-release.sh OWNER/REPO TAG [--pattern GLOB] [--version-cmd "CMD"] [--smoke "CMD"]
#   Downloads every asset (or those matching --pattern), checks each against the checksum file
#   (SHA256SUMS, or a *checksums.txt), and checks each one's build
#   attestation came from OWNER/REPO. --version-cmd must print the tag's version (without the v);
#   --smoke must exit 0. In both, {dir} is the folder holding the downloaded assets.
# Exits 1 on the first check that fails, and prints what passed. It never publishes.
set -uo pipefail
repo=${1:?usage: bash verify-release.sh OWNER/REPO TAG [--version-cmd CMD] [--smoke CMD]}
tag=${2:?usage: bash verify-release.sh OWNER/REPO TAG [--version-cmd CMD] [--smoke CMD]}
shift 2; version_cmd=""; smoke=""; pattern=""
while [ $# -gt 0 ]; do
  case $1 in --pattern) pattern=$2; shift 2 ;; --version-cmd) version_cmd=$2; shift 2 ;; --smoke) smoke=$2; shift 2 ;; *) echo "unknown option $1"; exit 2 ;; esac
done
dir=$(mktemp -d); trap 'rm -rf "$dir"' EXIT
fail() { echo "FAIL  $*"; exit 1; }

sums=$(gh release view "$tag" -R "$repo" --json assets --jq '.assets[].name' | grep -E '^SHA256SUMS$|checksums\.txt$' | head -1)
[ -n "$sums" ] || fail "no SHA256SUMS or *checksums.txt in $tag"
gh release download "$tag" -R "$repo" -D "$dir" -p "$sums" -p "${pattern:-*}" || fail "couldn't download the assets of $tag"
[ "$(ls "$dir" | grep -vxF "$sums" | wc -l)" -gt 0 ] || fail "no assets matched${pattern:+ --pattern $pattern}, so there's nothing to check"
# --ignore-missing: with --pattern, only some of the listed files are here.
(cd "$dir" && { command -v sha256sum >/dev/null && sha256sum --ignore-missing -c "$sums" || shasum -a 256 --ignore-missing -c "$sums"; }) >/dev/null ||
  fail "a checksum doesn't match $sums"
echo "ok    checksums match $sums"
for f in "$dir"/*; do
  [ "$(basename "$f")" = "$sums" ] && continue
  gh attestation verify "$f" --repo "$repo" >/dev/null 2>&1 || fail "no valid build attestation from $repo for $(basename "$f")"
done
echo "ok    every asset has a build attestation from $repo"
if [ -n "$version_cmd" ]; then
  out=$(bash -c "${version_cmd//\{dir\}/$dir}" 2>&1) || fail "--version-cmd failed: $out"
  grep -qF "${tag#v}" <<<"$out" || fail "--version-cmd printed \"$out\", not ${tag#v}"
  echo "ok    version prints ${tag#v}"
fi
if [ -n "$smoke" ]; then
  bash -c "${smoke//\{dir\}/$dir}" >/dev/null 2>&1 || fail "smoke test failed: $smoke"
  echo "ok    smoke test passed"
fi
echo "$tag is ready to publish: gh release edit $tag -R $repo --draft=false"
