#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# A control that cannot answer says so — one line naming the argument, exit 2 — never a skip, never
# a silent zero (contract-session § 6, the INSTRUMENT bound): the law in force on a folder that is
# none, or on a bare name where a folder is expected, in every mode; the law in force, the atlas
# and the battery on an --own that names no memory folder. A folder that exists answers as before.
# Usage:  bash tests/readers.sh      (writes nothing outside a temporary folder)
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok    readers  $1"; }
bad() { echo "FAIL  readers  $1"; fail=1; }
bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  readers  the fixture could not be built"; exit 1; }
cd "$tmp/fx" || exit 1
inf="$repo/skills/crit-in-force/in-force.sh"; atl="$repo/skills/crit-memory-index/memory-index.sh"; lint="$repo/skills/crit-doc-lint/doc-lint.sh"
expect2() {   # $1 = the leg, $2 = the argument the one line must name, then the command
  local label="$1" arg="$2" out rc n; shift 2
  out=$("$@" 2>&1); rc=$?; n=$(printf '%s\n' "$out" | grep -c .)
  if [ "$rc" = 2 ] && [ "$n" = 1 ] && printf '%s' "$out" | grep -qF -- "$arg"; then ok "$label"
  else bad "$label — exit $rc, $n line(s): $(printf '%s' "$out" | head -1 | cut -c1-110)"; fi
}
expect2 "the law in force --check on a folder that is none: exit 2, one line naming it" .critos/memory/a7 bash "$inf" --check .critos/memory/a7
expect2 "the law in force --check on a bare name: exit 2, one line naming it" a2 bash "$inf" --check a2
expect2 "the law in force (write) on a folder that is none: exit 2" .critos/memory/a7 bash "$inf" .critos/memory/a7
expect2 "the law in force --lines on a bare name: exit 2" a2 bash "$inf" --lines a2
expect2 "the law in force --own naming no memory folder: exit 2" a7 bash "$inf" --check --own a7
expect2 "the atlas --own naming no memory folder: exit 2" a7 bash "$atl" --check --own a7
expect2 "the battery --own naming no memory folder: exit 2, one line" a7 env DOC_LINT_NO_CONSTELLATION=1 CRITOS_AUTO_MEMORY="$tmp/fx.auto-memory" bash "$lint" --own a7
# the negatives: a folder that exists, an owner that exists, answer — exit 0 or 1, never 2
bash "$inf" --check .critos/memory/a2 >/dev/null 2>&1; rc=$?
[ "$rc" != 2 ] && ok "the law in force --check on a folder that exists answers (exit $rc)" || bad "the law in force --check on .critos/memory/a2 exits 2"
bash "$inf" --check --own a2 >/dev/null 2>&1; rc=$?
[ "$rc" != 2 ] && ok "the law in force --check --own a2 answers (exit $rc)" || bad "the law in force --check --own a2 exits 2"
exit $fail
