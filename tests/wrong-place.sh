#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The wrong place: every control run from a folder that is not inside a git repository must NAME
# the likely cause - a session opened ABOVE the repo, where none of the repo's .claude/ is loaded -
# and the remedy. "not a git repo" alone reads as "run git init", which is the wrong action there.
#     bash tests/wrong-place.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
controls=(
  skills/crit-status-check/status-check.sh
  skills/crit-status-check/inbox-check.sh
  skills/crit-doc-lint/doc-lint.sh
  skills/crit-memory-index/memory-index.sh
)
for c in "${controls[@]}"; do
  out="$(cd "$tmp" && GIT_CEILING_DIRECTORIES="$tmp" bash "$repo/$c" --me 1 .critos/memory/a1 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ] && printf '%s' "$out" | grep -q 'ABOVE the repo' && printf '%s' "$out" | grep -q 'repo root'; then
    echo "ok    wrong-place  $(basename "$c")"
  else
    echo "FAIL  wrong-place  $(basename "$c") (exit $rc): expected the cause and the remedy, got:"; printf '%s\n' "$out" | sed 's/^/        /'; fail=1
  fi
done
exit $fail
