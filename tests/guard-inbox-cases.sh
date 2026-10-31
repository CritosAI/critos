#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# Feeds the inbox guard a table of situations — the fixture's inbox with uncommitted hands, a
# write by the editing tools, a commit by pathspec or from the index — and prints one verdict
# per case (ASK:<kind> | PASS). tests/run.sh compares the output with
# tests/expected-guard-inbox.txt: a verdict that moves is a regression in either direction — a
# carried neighbour, or an ask on a one-hand write.
#
# Usage:  bash tests/guard-inbox-cases.sh <hook.sh> <fixture-repo>
set -uo pipefail
HOOK="$1"; REPO="$2"; L=".critos"
INB="$L/shared/HANDOFFS.md"; A="$REPO/$INB"

verdict() {   # $1 = label, stdin = the payload; the hook runs with cwd = $REPO
  local out kind
  out=$(cd "$REPO" && bash "$HOOK" 2>/dev/null)
  if printf '%s' "$out" | grep -q '"permissionDecision":"ask"'; then
    kind=$(printf '%s' "$out" | sed -E 's/.*"permissionDecisionReason":"([A-Z]+).*/\1/')
    printf 'ASK:%-8s %s\n' "$kind" "$1"
  else
    printf 'PASS         %s\n' "$1"
  fi
}
pay_edit()  { node -e 'console.log(JSON.stringify({tool_name:"Edit",tool_input:{file_path:process.argv[1],old_string:process.argv[2],new_string:process.argv[3]}}))' "$1" "$2" "$3"; }
pay_write() { node -e 'console.log(JSON.stringify({tool_name:"Write",tool_input:{file_path:process.argv[1],content:process.argv[2]}}))' "$1" "$2"; }
pay_bash()  { node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1"; }

committed=$(cd "$REPO" && git show "HEAD:$INB")
body=$(printf '%s\n' "$committed" | tail -n +2)
e2='- 2026-09-15 — AGENT 2 → AGENT 3: **[OPEN — my own line. Done when: read]** [docs/a.md]'
e4='- 2026-09-16 — AGENT 4 → AGENT 2: **[OPEN — a neighbour line. Done when: read]** [docs/b.md]'
sub7='  - 2026-09-16 — AGENT 7: served, see the report'
# the working-tree inbox = the title, the lines given, then the committed body
set_tree() { { printf '# inbox\n'; for l in "$@"; do printf '%s\n' "$l"; done; printf '%s\n' "$body"; } > "$A"; }
restore()  { ( cd "$REPO" && git reset -q && git checkout -q -- . ); }

# ---- the write edge: the editing tools ---------------------------------------------------------
restore
pay_edit "$A" '# inbox' "# inbox
$e2" | verdict "Edit: a new entry of mine on a clean tree"
pay_edit "$REPO/docs/orphan.md" 'nobody' 'somebody' | verdict "Edit: another file"
set_tree "$e4"
pay_edit "$A" '# inbox' "# inbox
$e2" | verdict "Edit: my entry while the tree carries a neighbour's uncommitted entry"
pay_write "$A" "# inbox
$e2
$e4
$body" | verdict "Write: the whole file, my entry added beside the neighbour's"
pay_edit "$A" '# inbox' '# inbox — read it top-down' | verdict "Edit: the head only, beside the neighbour's entry (prose is not read)"
pay_bash "sed -i '1a $e2' $INB" | verdict "Bash: a shell write beside the neighbour's entry (its hand unreadable)"
pay_bash "grep -n AGENT $INB" | verdict "Bash: a read of the inbox beside the neighbour's entry"
pay_bash "git diff -- $INB" | verdict "Bash: git diff of the inbox beside the neighbour's entry"
set_tree "$e2"
pay_bash "sed -i '1a $e4' $INB" | verdict "Bash: a shell write while only my own entry is uncommitted"

# ---- the commit edge: by pathspec (the working tree) ---------------------------------------------
set_tree "$e2"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: one hand"
set_tree "$e4" "$e2"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: two hands in the working tree"
pay_bash "git -C \"$REPO\" commit -m \"x\" -- $INB" | verdict "commit by pathspec with -C: two hands"
pay_bash "git commit -m \"x\" -- docs/orphan.md" | verdict "commit by pathspec of another file while the inbox carries two hands"
# a flip: the recipient's hand
flipped=$(printf '%s\n' "$committed" | sed 's/\*\*\[OPEN — the schema needs a column\]\*\*/**[ABSORBED 2026-09-16 by A3 — added]**/')
printf '%s\n' "$flipped" > "$A"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: one flipped token (the recipient's hand)"
{ printf '%s\n' "$flipped" | head -1; printf '%s\n' "$e2"; printf '%s\n' "$flipped" | tail -n +2; } > "$A"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: a flip by the recipient and a new entry by another"
# a sub-line: the hand it names
{ printf '# inbox\n'; printf '%s\n' "$body" | head -1; printf '%s\n' "$sub7"; printf '%s\n' "$body" | tail -n +2; } > "$A"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: one sub-line"
{ printf '# inbox\n'; printf '%s\n' "$e2"; printf '%s\n' "$body" | head -1; printf '%s\n' "$sub7"; printf '%s\n' "$body" | tail -n +2; } > "$A"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec: a sub-line of one agent and an entry of another"

# ---- the commit edge: from the index (the escape) ------------------------------------------------
restore
set_tree "$e2"; ( cd "$REPO" && git add -- "$INB" )
set_tree "$e4" "$e2"
pay_bash 'git commit -m "x"' | verdict "commit from the index: my hunk alone staged, the neighbour's left in the tree"
pay_bash "git commit -m \"x\" -- $INB" | verdict "commit by pathspec after staging my hunk: the tree still carries two"
( cd "$REPO" && printf 'y\n' >> src/x.js && git add -- src/x.js )
pay_bash 'git commit -m "x"' | verdict "commit from the index: my hunk staged beside another path"
restore
set_tree "$e4" "$e2"; ( cd "$REPO" && git add -- "$INB" )
pay_bash 'git commit -m "x"' | verdict "commit from the index: two hands staged"
restore
pay_bash 'git commit -m "x"' | verdict "commit from the index: nothing of the inbox staged"
restore
