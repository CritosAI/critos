#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The battery has two scopes, and the owner's name chooses (contract-session § 2 step 4). On the
# fixture, as a2: the battery reads the runner's scope — a2's memory folder, a2's ids, the inbox
# entries AGENT 2 authored, the links of the files under a2's roots — and its tally is
# tests/expected-findings-own-a2.txt; the eleven tree-wide checks print their skip line; the scope
# line and the closing stamp name a2. With --all, as a2: the whole battery's tally
# (tests/expected-findings.txt), no skip, the stamp says whole.
# Usage:  bash tests/scope.sh [--update]      (writes nothing outside a temporary folder; --update
#         rewrites the runner's expected tally — review the diff, commit it WITH its cause)
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
update=0; [ "${1:-}" = "--update" ] && update=1
fail=0
ok() { echo "ok    scope  $1"; }
bad() { echo "FAIL  scope  $1"; fail=1; }
bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  scope  the fixture could not be built"; exit 1; }
cd "$tmp/fx" || exit 1
lint() { DOC_LINT_NO_CONSTELLATION=1 CRITOS_AUTO_MEMORY="$tmp/fx.auto-memory" bash "$repo/skills/crit-doc-lint/doc-lint.sh" "$@" 2>&1; }
tally() { grep -E '^[A-Z][A-Za-z0-9-]+ ' "$1" | cut -d' ' -f1 | LC_ALL=C sort | uniq -c | awk '$2 == "PIN-DRIFT" { print "present PIN-DRIFT"; next } { print $1, $2 }'; }
# 1. the runner's scope, as a2
lint --own a2 > "$tmp/a2.txt"
tally "$tmp/a2.txt" > "$tmp/a2.tally"
exp="$here/expected-findings-own-a2.txt"
if [ "$update" = 1 ]; then cp "$tmp/a2.tally" "$exp"; echo "updated  $exp"
elif diff "$exp" "$tmp/a2.tally" > "$tmp/a2.diff"; then ok "as a2 the tally is the runner's ($(grep -c . "$exp") lines)"
else bad "as a2 the tally differs — expected (<) vs got (>):"; sed 's/^/        /' "$tmp/a2.diff"; fi
skips=$(grep -c '^(skipped — a tree-wide check' "$tmp/a2.txt")
[ "$skips" = 11 ] && ok "the eleven tree-wide checks are skipped and say so" || bad "$skips skip lines, not 11"
grep -q "^### scope: the runner's — a2:" "$tmp/a2.txt" && ok "the scope line names a2" || bad "no scope line naming a2"
grep -qE '^### doc-lint done — 28 checks in [0-9]+s · scope: a2 \(' "$tmp/a2.txt" && ok "the closing stamp names the scope" || bad "the closing stamp does not name a2: $(grep '^### doc-lint done' "$tmp/a2.txt")"
grep -qE '^(awk|gawk|sed|grep|bash|realpath|node|tar): ' "$tmp/a2.txt" && bad "an interpreter diagnostic in the runner's run: $(grep -E '^(awk|gawk|sed|grep|bash|realpath|node|tar): ' "$tmp/a2.txt" | head -1)"
# 2. the whole, as a2 with --all
lint --own a2 --all > "$tmp/all.txt"
if tally "$tmp/all.txt" | diff "$here/expected-findings.txt" - > "$tmp/all.diff"; then ok "with --all the tally is the whole battery's"
else bad "with --all the tally differs from the whole — expected (<) vs got (>):"; sed 's/^/        /' "$tmp/all.diff"; fi
[ "$(grep -c '^(skipped — a tree-wide check' "$tmp/all.txt")" = 0 ] && ok "with --all nothing is skipped" || bad "with --all a check was skipped"
grep -q '^### scope: whole' "$tmp/all.txt" && grep -q ' · scope: whole · ' "$tmp/all.txt" && ok "with --all the scope line and the stamp say whole" || bad "with --all the scope is not said whole"
exit $fail
