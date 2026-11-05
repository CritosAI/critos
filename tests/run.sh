#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The deterministic tests of CritOS. Run them before proposing any change to a control:
#     bash tests/run.sh
# Needs: bash, git, node. Writes nothing outside a temporary folder.
#
#   1. the battery   every finding token of crit-doc-lint fires on the fixture, with the expected
#                    tally (tests/expected-findings.txt). PIN-DRIFT is checked for PRESENCE only:
#                    between two releases the tier's bytes legitimately differ from the last
#                    ledger rows, so its count is not stable. And the law in force generated for
#                    the fixture's a2 counts its live entries and names the uncarried ones; for
#                    a3 it counts the one untiered rule line in its head.
#   2. the guards    every verdict of the command table (tests/expected-guard.txt), and every
#                    verdict of the inbox guard's situations (tests/expected-guard-inbox.txt).
#   3. the licence   every file carries the SPDX line, or a declared exemption (tests/licence.sh).
#   4. the scaffold  a scaffold of an empty repo equals tests/expected-scaffold/ byte for byte, and
#                    the controls read the newborn project as clean (tests/scaffold.sh).
#   5. the wrong place  every control run from outside a git repository names the likely cause
#                    (a session opened above the repo) and the remedy (tests/wrong-place.sh).
#   6. the installer  the platform's installer, into a sandbox home: installs, is idempotent,
#                    keeps what is yours, uninstalls only its own, refuses a linked folder
#                    (tests/install.sh) - install.ps1 under Git Bash on Windows, install.sh elsewhere.
#   7. the commit format  every rule of the public subject line fires in both directions
#                    (tests/commit-format.sh); the same checker reads a pull request's
#                    subjects in CI.
#   8. the version cited  every install line of the README and the install guide names the
#                    release system/VERSION declares (tests/version-cited.sh): a page that
#                    sends a newcomer to an older tag cannot be cut.
#   9. the owner    a generator reads a folder it does not own as committed and writes only in
#                    the folders its runner owns: a neighbour's uncommitted entry never reaches
#                    what another owner writes, and an unchanged index is not rewritten
#                    (tests/own.sh).
# To change an expectation on purpose: run with --update, review the diff, commit it WITH the
# change that caused it.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
update=0; [ "${1:-}" = "--update" ] && update=1
fail=0

bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  the fixture could not be built"; exit 1; }

# The auto-memory the citation leg reads is the fixture's own (planted beside it), never this
# machine's: the leg is seen firing on every machine, and no note of yours reaches the tally.
( cd "$tmp/fx" && DOC_LINT_NO_CONSTELLATION=1 CRITOS_AUTO_MEMORY="$tmp/fx.auto-memory" bash "$repo/skills/crit-doc-lint/doc-lint.sh" 2>&1 ) > "$tmp/battery.txt"
grep -E '^[A-Z][A-Za-z0-9-]+ ' "$tmp/battery.txt" | cut -d' ' -f1 | sort | uniq -c \
  | awk '$2 == "PIN-DRIFT" { print "present PIN-DRIFT"; next } { print $1, $2 }' > "$tmp/findings.txt"
# An interpreter diagnostic in the battery's output is a check reading something other than
# what its text says (a gawk warning once meant three legs compared a boolean): the tally above
# cannot see it, because a diagnostic starts in lowercase. Known positive: `awk: cmd. line:…`.
if grep -qE '^(awk|gawk|sed|grep|bash|realpath|node): ' "$tmp/battery.txt"; then
  echo "FAIL  battery stderr — an interpreter diagnostic in the battery's output:"
  grep -E '^(awk|gawk|sed|grep|bash|realpath|node): ' "$tmp/battery.txt" | sort | uniq -c | head -5 | sed 's/^/        /'
  fail=1
else echo "ok    battery stderr (no interpreter diagnostic in $(grep -c . "$tmp/battery.txt") lines)"; fi
# The law in force names what it cannot summarise: a2 holds five decisions and two lessons, four
# of them carrying their rule — the index says 4 of 7 and names the other three, per log.
( cd "$tmp/fx" && bash "$repo/skills/crit-in-force/in-force.sh" .critos/memory/a2 >/dev/null 2>&1 )
if grep -q '^\*\*Carried:\*\* 4 of 7 live entries' "$tmp/fx/.critos/memory/a2/IN-FORCE.md" \
   && grep -q '^\*\*Uncarried:\*\* `ADR-A2-002` — in `DECISIONS.md`' "$tmp/fx/.critos/memory/a2/IN-FORCE.md" \
   && grep -q '^\*\*Uncarried:\*\* `L-A2-001`, `L-A2-002` — in `LESSONS-LEARNED.md`' "$tmp/fx/.critos/memory/a2/IN-FORCE.md"; then
  echo "ok    in-force (the index counts 4 of 7 live entries and names the three uncarried)"
else
  echo "FAIL  in-force — the index does not count its live entries or name the uncarried ones:"
  grep -E '^\*\*(Carried|Uncarried):' "$tmp/fx/.critos/memory/a2/IN-FORCE.md" 2>/dev/null | sed 's/^/        /'; fail=1
fi
# The head counts the untiered beside the uncarried: a3 carries 302 rules in force, one with no tier
# on its line and no Enforcement: field in its entry — the index says 1 of 302 and prints tier ? there.
( cd "$tmp/fx" && bash "$repo/skills/crit-in-force/in-force.sh" .critos/memory/a3 >/dev/null 2>&1 )
if grep -q '^\*\*Untiered:\*\* 1 of 302 rule lines' "$tmp/fx/.critos/memory/a3/IN-FORCE.md" \
   && grep -q '^- `ADR-A3-002` · a rule with no tier anywhere · tier ?$' "$tmp/fx/.critos/memory/a3/IN-FORCE.md"; then
  echo "ok    in-force (the a3 index counts 1 of 302 untiered and prints tier ? on the line)"
else
  echo "FAIL  in-force — the a3 index does not count its untiered line:"
  grep -E '^\*\*(Carried|Uncarried|Untiered):|ADR-A3-002' "$tmp/fx/.critos/memory/a3/IN-FORCE.md" 2>/dev/null | sed 's/^/        /'; fail=1
fi
bash "$here/guard-cases.sh" "$repo/hooks/guard-user-driven-actions.sh" "$tmp/fx" 2>/dev/null > "$tmp/guard.txt"
bash "$here/guard-inbox-cases.sh" "$repo/hooks/guard-inbox.sh" "$tmp/fx" 2>/dev/null > "$tmp/guard-inbox.txt"

for t in findings guard guard-inbox; do
  exp="$here/expected-$t.txt"
  if [ "$update" = 1 ]; then cp "$tmp/$t.txt" "$exp"; echo "updated  $exp"; continue; fi
  if diff "$exp" "$tmp/$t.txt" > "$tmp/$t.diff"; then echo "ok    $t ($(grep -c . "$exp") lines)"
  else echo "FAIL  $t — expected (<) vs got (>):"; sed 's/^/        /' "$tmp/$t.diff"; fail=1; fi
done
bash "$here/licence.sh" || fail=1
if [ "$update" = 1 ]; then bash "$here/scaffold.sh" --update || fail=1; else bash "$here/scaffold.sh" || fail=1; fi
bash "$here/wrong-place.sh" || fail=1
bash "$here/install.sh" || fail=1
bash "$here/commit-format.sh" || fail=1
bash "$here/version-cited.sh" || fail=1
bash "$here/own.sh" || fail=1
exit $fail
