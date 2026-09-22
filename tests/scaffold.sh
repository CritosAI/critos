#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The scaffold is DETERMINISTIC: same input, same files, byte for byte. This test scaffolds an
# empty repo and demands:
#   1. the instantiated files equal tests/expected-scaffold/<path>.expected byte for byte (the date
#      is pinned; the suffix keeps the documentation checks from reading them as live docs);
#   2. the pinned tier and the steward's definition equal their sources;
#   3. the controls read a newborn project as CLEAN: zero findings from the battery, no roadmap
#      item that nobody opened, an atlas that is fresh and holds no decision and no lesson;
#   4. a second run refuses (exit 3) and writes nothing; --resume creates only what is missing;
#   5. --agent-memory creates a new agent's triple, and the battery is still clean.
# Usage: bash tests/scaffold.sh [--update]      (called by tests/run.sh)
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
exp="$here/expected-scaffold"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
update=0; [ "${1:-}" = "--update" ] && update=1
fail=0; bad() { echo "FAIL  scaffold — $*"; fail=1; }

t="$tmp/expected-project"; mkdir -p "$t"; git -C "$t" init -q
run() { ( cd "$t" && CRITOS_SCAFFOLD_DATE=2026-01-01 bash "$repo/skills/crit-scaffold-project/scaffold.sh" "$@" ); }
run > "$tmp/run1.txt" 2>&1 || bad "the first run exited non-zero: $(tail -1 "$tmp/run1.txt")"

# 1. the instances, byte for byte
inst="CLAUDE.md .critos/project/settings.md .critos/project/agents.md .critos/memory/a1/STATUS.md
.critos/memory/a1/DECISIONS.md .critos/memory/a1/LESSONS-LEARNED.md .critos/shared/HANDOFFS.md
.critos/shared/ROADMAP.md .critos/shared/CONTRACTS.md"
if [ "$update" = 1 ]; then
  rm -rf "$exp"; for f in $inst; do mkdir -p "$exp/$(dirname "$f")"; cp "$t/$f" "$exp/$f.expected"; done
  echo "updated  $exp"
else
  for f in $inst; do
    [ -f "$exp/$f.expected" ] || { bad "no expected file for $f"; continue; }
    cmp -s "$exp/$f.expected" "$t/$f" || { bad "$f differs from tests/expected-scaffold/ (run with --update, review the diff)"; diff "$exp/$f.expected" "$t/$f" | head -8 | sed 's/^/        /'; }
  done
fi
leftover=$(grep -rlE 'SCAFFOLD:|<PROJECT_NAME>|<TODAY>|<Domain>' "$t/CLAUDE.md" "$t/.critos/project" "$t/.critos/memory" "$t/.critos/shared" 2>/dev/null || true)
[ -z "$leftover" ] || bad "a mechanical placeholder survived in: $leftover"
[ "$(cat $(for f in $inst; do printf '%s ' "$t/$f"; done) | tr -cd '\015' | wc -c)" = 0 ] || bad "an instance carries a carriage return"

# 2. what is copied verbatim
for f in "$repo"/system/*; do cmp -s "$f" "$t/.critos/system/$(basename "$f")" || bad "the pinned $(basename "$f") differs from its source"; done
cmp -s "$repo/agents/agent-1.md" "$t/.claude/agents/agent-1.md" || bad "the steward's definition differs from its source"

# 3. a newborn project reads as clean - before AND after its first commit
lint() { ( cd "$t" && DOC_LINT_NO_CONSTELLATION=1 bash "$repo/skills/crit-doc-lint/doc-lint.sh" 2>&1 ) | grep -E '^[A-Z][A-Za-z0-9-]+  ' | grep -v '^PIN-DRIFT' || true; }
f0=$(lint); [ -z "$f0" ] || bad "the battery finds something in an uncommitted scaffold: $(printf '%s' "$f0" | head -3)"
( cd "$t" && git add -A >/dev/null 2>&1 && git -c user.name=t -c user.email=t@example.invalid commit -q -m scaffold )
f1=$(lint); [ -z "$f1" ] || bad "the battery finds something in a committed scaffold: $(printf '%s' "$f1" | head -3)"
for n in 1 2; do
  # captured first: with pipefail, a `grep -q` that exits early turns the pipeline's status into a SIGPIPE
  sc=$( cd "$t" && bash "$repo/skills/crit-status-check/status-check.sh" --me $n .critos/memory/a1 2>&1 || true )
  printf '%s\n' "$sc" | grep -E '^[[:space:]]+R[0-9]+ \[' >/dev/null && bad "the status check shows AGENT $n a roadmap item that nobody opened"
done
( cd "$t" && bash "$repo/skills/crit-memory-index/memory-index.sh" --check >/dev/null 2>&1 ) || bad "the atlas the scaffold generated is already stale"
grep -qE '\| 0 ADR \|' "$t/MEMORY-INDEX.md" || bad "the atlas counts a decision in a log that was born empty"
grep -qE 'no L- ids' "$t/MEMORY-INDEX.md" || bad "the atlas counts a lesson in a log that was born empty"

# 4. a second run refuses; --resume fills only what is missing
run > "$tmp/run2.txt" 2>&1; rc=$?
[ "$rc" = 3 ] || bad "a second run on a scaffolded repo exited $rc, not 3"
[ -z "$(git -C "$t" status --porcelain)" ] || bad "a refused run wrote something"
rm "$t/.critos/shared/ROADMAP.md"
run --resume > "$tmp/run3.txt" 2>&1 || bad "--resume exited non-zero"
grep -q '^done     1 created' "$tmp/run3.txt" || bad "--resume did not create exactly the one missing file: $(tail -1 "$tmp/run3.txt")"
cmp -s "$exp/.critos/shared/ROADMAP.md.expected" "$t/.critos/shared/ROADMAP.md" || [ "$update" = 1 ] || bad "--resume recreated ROADMAP.md differently"

# 5. a new agent's memory
run --agent-memory 2 "Billing engine" > "$tmp/run4.txt" 2>&1 || bad "--agent-memory exited non-zero"
head -1 "$t/.critos/memory/a2/STATUS.md" | grep -q '^# Billing engine — Status (AGENT 2)$' || bad "the new agent's STATUS has the wrong title"
grep -q 'ADR-A2-###' "$t/.critos/memory/a2/DECISIONS.md" || bad "the new agent's log does not carry its own id scheme"
f2=$(lint | grep -v '^MEMORY-SHAPE' || true); [ -z "$f2" ] || bad "the battery finds something after --agent-memory: $(printf '%s' "$f2" | head -3)"

[ "$fail" = 0 ] && echo "ok    scaffold (9 instances byte for byte, a newborn project reads clean, refuse / resume / agent-memory)"
exit $fail
