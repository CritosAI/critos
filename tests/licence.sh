#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# Licence coverage: every tracked file carries the SPDX line, or is listed in
# tests/licence-exempt.txt with its reason. Run by tests/run.sh.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"; cd "$repo" || exit 1
fail=0; n=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  n=$((n + 1))
  grep -q 'SPDX-License-Identifier: Apache-2.0' "$f" 2>/dev/null && continue
  ok=0
  while IFS=$'\t' read -r pat why; do
    case "$pat" in ''|'#'*) continue ;; esac
    # shellcheck disable=SC2254
    case "$f" in $pat) ok=1; break ;; esac
  done < "$here/licence-exempt.txt"
  [ "$ok" = 1 ] || { echo "NO-LICENCE-HEADER  $f  (add the SPDX line, or list it in tests/licence-exempt.txt with its reason)"; fail=1; }
done < <( { git ls-files; git ls-files --others --exclude-standard; } | sort -u )
[ "$fail" = 0 ] && echo "ok    licence ($n files: a header, or a declared exemption)"
exit $fail
