#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# Feeds a table of commands to the guard hook as PreToolUse payloads and prints one verdict per
# case (ASK:<kind> | PASS). tests/run.sh compares the output with tests/expected-guard.txt: a
# verdict that moves is a regression in either direction — a missed push, or an ask on a grep.
#
# Usage:  bash tests/guard-cases.sh <hook.sh> <fixture-repo>
set -uo pipefail
HOOK="$1"; REPO="$2"; L=".critos"

verdict() {   # $1 = command string, run with cwd = $REPO
  local out kind
  out=$(cd "$REPO" && node -e 'console.log(JSON.stringify({tool_name:"Bash",tool_input:{command:process.argv[1]}}))' "$1" | bash "$HOOK" 2>/dev/null)
  if printf '%s' "$out" | grep -q '"permissionDecision":"ask"'; then
    kind=$(printf '%s' "$out" | sed -E 's/.*"permissionDecisionReason":"([A-Z]+).*/\1/')
    printf 'ASK:%-8s %s\n' "$kind" "$1"
  else
    printf 'PASS         %s\n' "$1"
  fi
}

while IFS= read -r c; do [ -n "$c" ] && verdict "$c"; done <<'CASES'
git push
git push origin master
git -C "/c/some path/with spaces/repo" push
git.exe --no-pager push origin
git -c user.name=x push
cd sub && git push
bash -c "git push"
sh -c 'git push origin'
git push --help
grep -rn "git push" doc/
git log --grep="git push"
git commit -m "guard: catch 'git push'" -- a.txt
echo "git push is user-driven"
git stash
git stash pop
git add -A
git add --all
git add .
git add src/x.js
git commit -am "x"
git commit --all -m "x"
git commit -m "x" -- src/x.js
git checkout .
git restore -- .
git checkout main
git restore src/x.js
git clean -fd
git clean -fx
git clean -nd
git clean --dry-run -fd
git status
echo start; git push
echo "deploying" && git push origin main
cat notes.txt; git stash
grep -q x f && git add -A
ls -h; git push
git push -h && git push origin
printf 'x' | cat; git clean -fd
echo one; echo two
grep -rn "git push" doc/ | head -3
cat notes.txt | grep push
git push 2>&1 | tail -1
CASES

# ---- the staged-set re-check: what is about to be committed, not what the command says ----
( cd "$REPO" && echo s >> "$L/memory/a2/STATUS.md" && echo s >> "$L/memory/a3/STATUS.md" && git add -- "$L/memory/a2/STATUS.md" "$L/memory/a3/STATUS.md" )
verdict "git commit -m \"two folders, from the index\""
verdict "git commit -m \"two folders, by pathspec\" -- $L/memory/a2/STATUS.md $L/memory/a3/STATUS.md"
verdict "git commit -m \"one folder, by pathspec\" -- $L/memory/a2/STATUS.md"
( cd "$REPO" && git reset -q -- "$L/memory/a3/STATUS.md" )
verdict "git commit -m \"one folder, from the index\""
( cd "$REPO" && git reset -q && git checkout -q -- . )
