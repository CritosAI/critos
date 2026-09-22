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
#                    ledger rows, so its count is not stable.
#   2. the guard     every verdict of the command table (tests/expected-guard.txt).
#   3. the licence   every file carries the SPDX line, or a declared exemption (tests/licence.sh).
#   4. the scaffold  a scaffold of an empty repo equals tests/expected-scaffold/ byte for byte, and
#                    the controls read the newborn project as clean (tests/scaffold.sh).
#   5. the wrong place  every control run from outside a git repository names the likely cause
#                    (a session opened above the repo) and the remedy (tests/wrong-place.sh).
#   6. the installer  the platform's installer, into a sandbox home: installs, is idempotent,
#                    keeps what is yours, uninstalls only its own, refuses a linked folder
#                    (tests/install.sh) - install.ps1 under Git Bash on Windows, install.sh elsewhere.
# To change an expectation on purpose: run with --update, review the diff, commit it WITH the
# change that caused it.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
update=0; [ "${1:-}" = "--update" ] && update=1
fail=0

bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  the fixture could not be built"; exit 1; }

( cd "$tmp/fx" && DOC_LINT_NO_CONSTELLATION=1 bash "$repo/skills/crit-doc-lint/doc-lint.sh" 2>&1 ) \
  | grep -E '^[A-Z][A-Za-z0-9-]+ ' | cut -d' ' -f1 | sort | uniq -c \
  | awk '$2 == "PIN-DRIFT" { print "present PIN-DRIFT"; next } { print $1, $2 }' > "$tmp/findings.txt"
bash "$here/guard-cases.sh" "$repo/hooks/guard-user-driven-actions.sh" "$tmp/fx" 2>/dev/null > "$tmp/guard.txt"

for t in findings guard; do
  exp="$here/expected-$t.txt"
  if [ "$update" = 1 ]; then cp "$tmp/$t.txt" "$exp"; echo "updated  $exp"; continue; fi
  if diff "$exp" "$tmp/$t.txt" > "$tmp/$t.diff"; then echo "ok    $t ($(grep -c . "$exp") lines)"
  else echo "FAIL  $t — expected (<) vs got (>):"; sed 's/^/        /' "$tmp/$t.diff"; fail=1; fi
done
bash "$here/licence.sh" || fail=1
if [ "$update" = 1 ]; then bash "$here/scaffold.sh" --update || fail=1; else bash "$here/scaffold.sh" || fail=1; fi
bash "$here/wrong-place.sh" || fail=1
bash "$here/install.sh" || fail=1
exit $fail
