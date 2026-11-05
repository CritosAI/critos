#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# A generator reads a folder it does not own as committed, and writes only in the folders its
# runner owns (contract-memory § 6). On the fixture, with its indexes committed: a3's log gains an
# entry nobody committed; a run owned by a2 must leave a3's index untouched and read a3 as
# committed (the new id absent from a3's law as checked, and from the atlas a2 writes); a3's own
# run must see it; a second run of an unchanged index must write nothing; without a name the law
# in force writes nothing and says so.
# Usage:  bash tests/own.sh        (writes nothing outside a temporary folder)
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok    own  $1"; }
bad() { echo "FAIL  own  $1"; fail=1; }
bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  own  the fixture could not be built"; exit 1; }
cd "$tmp/fx" || exit 1
inf="$repo/skills/crit-in-force/in-force.sh"; atl="$repo/skills/crit-memory-index/memory-index.sh"
# each owner generates its own index and commits; then the atlas, generated over the committed
# indexes (their presence is a cell of its folder table) and committed in turn
bash "$inf" --own a2 >/dev/null 2>&1; bash "$inf" --own a3 >/dev/null 2>&1
git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@example.invalid commit -qm "indexes" >/dev/null 2>&1
bash "$atl" --own a2 >/dev/null 2>&1
git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@example.invalid commit -qm "atlas" >/dev/null 2>&1
# a3's owner writes a new entry and does not commit it
printf '\n## ADR-A3-777 — not yet committed\n**Carries.**\n- `ADR-A3-777` · a rule a neighbour must not carry · binds: fixture · tier 3\n' >> .critos/memory/a3/DECISIONS.md
# 1. a run owned by a2 writes a2 only — and nothing, since a2's content did not change
out=$(bash "$inf" --own a2 2>&1)
printf '%s\n' "$out" | grep -q '^unchanged .critos/memory/a2/IN-FORCE.md' && ok "a2's index unchanged: nothing written" || bad "a2's index should read unchanged: $(printf '%s' "$out" | head -2 | tr '\n' ' ')"
printf '%s\n' "$out" | grep -q 'a3/IN-FORCE' && bad "a run owned by a2 touched a3's index" || ok "a3's index not written by a2's run"
[ -z "$(git status --porcelain -- .critos/memory/a3/IN-FORCE.md)" ] && ok "a3's index clean in the tree after a2's run" || bad "a3's index dirty after a2's run"
# 2. the check owned by a2 reads a3 as committed: FRESH, the uncommitted entry unseen
chk=$(bash "$inf" --check --own a2 2>&1)
printf '%s\n' "$chk" | grep -q '^FRESH  .critos/memory/a3/IN-FORCE.md' && ok "a3 read as committed by a2's check: FRESH" || bad "a3 should read FRESH as committed: $(printf '%s' "$chk" | grep a3 | head -1)"
# 3. the check owned by a3 reads its own tree: STALE
chk3=$(bash "$inf" --check --own a3 2>&1)
printf '%s\n' "$chk3" | grep -q '^STALE  .critos/memory/a3/IN-FORCE.md' && ok "a3's own check reads its tree: STALE" || bad "a3's own check should be STALE: $(printf '%s' "$chk3" | grep a3 | head -1)"
# 4. the atlas owned by a2 lists no uncommitted id of a3, and an unchanged atlas is not rewritten
out2=$(bash "$atl" --own a2 2>&1)
grep -q 'ADR-A3-777' MEMORY-INDEX.md && bad "the atlas a2 writes lists a3's uncommitted id" || ok "the atlas a2 writes does not list a3's uncommitted id"
grep -q 'ADR-A3-001' MEMORY-INDEX.md && ok "the atlas a2 writes lists a3's committed entry (read at HEAD, not empty)" || bad "the atlas a2 writes read a3 as empty"
printf '%s\n' "$out2" | grep -q '^MEMORY-INDEX unchanged' && ok "the atlas unchanged: nothing written" || bad "the atlas should read unchanged: $out2"
# 5. without a name: the law in force writes nothing and says so
out3=$(bash "$inf" 2>&1)
printf '%s\n' "$out3" | grep -q 'no folder owned' && ok "without --own the law in force writes nothing and says so" || bad "without --own: $(printf '%s' "$out3" | head -1)"
# 6. a3's own run carries its new rule, and the atlas a3 writes lists it
bash "$inf" --own a3 >/dev/null 2>&1
grep -q 'ADR-A3-777' .critos/memory/a3/IN-FORCE.md && ok "a3's own run carries its new rule" || bad "a3's own run did not carry its new rule"
bash "$atl" --own a3 >/dev/null 2>&1
grep -q 'ADR-A3-777' MEMORY-INDEX.md && ok "the atlas a3 writes lists its own uncommitted id" || bad "the atlas a3 writes should list its own uncommitted id"
exit $fail
