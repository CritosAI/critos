#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The version the public pages tell a newcomer to install is the version being released: every
# `--branch vX.Y.Z` (the clone) and `checkout vX.Y.Z` (the update) in README.md and
# docs/guide-install.md names system/VERSION's release — its base X.Y.Z, a candidate's `-rc.N`
# stripped, because the pages are frozen between the last candidate and the final. A page that
# names an older tag sends every reader to a release the changelog already left behind.
#     bash tests/version-cited.sh [--root <checkout>]       run by tests/run.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; root="$(cd "$here/.." && pwd)"
[ "${1:-}" = "--root" ] && root="$(cd "$2" && pwd)"
ver=$(grep -oE '"system"[^,]*' "$root/system/VERSION" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[ -n "$ver" ] || { echo "FAIL  version-cited — system/VERSION declares no X.Y.Z"; exit 1; }
fail=0; n=0
for f in README.md docs/guide-install.md; do
  [ -f "$root/$f" ] || { echo "FAIL  version-cited — $f missing"; fail=1; continue; }
  while IFS= read -r line; do
    n=$((n + 1))
    cited=$(printf '%s' "$line" | grep -oE '(--branch|checkout) v[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?' | grep -oE 'v[0-9].*')
    [ "$cited" = "v$ver" ] && continue
    echo "FAIL  version-cited — $f names $cited where system/VERSION is $ver:  $(printf '%s' "$line" | cut -c1-90)"
    fail=1
  done < <(grep -nE '(--branch|checkout) v[0-9]+\.[0-9]+\.[0-9]+' "$root/$f" | cut -d: -f2-)
done
[ "$n" -ge 1 ] || { echo "FAIL  version-cited — no install line names a tag at all (the leg found nothing to read)"; fail=1; }
[ "$fail" = 0 ] && echo "ok    version-cited ($n install lines name v$ver)"
exit $fail
