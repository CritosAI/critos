#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# guard-user-driven-actions — a PreToolUse hook. It turns two rules of contract-session § 5 from
# prose into a control: "the agent stops at the local commit" and "never a worktree-wide git
# command in a shared worktree".
#
# It guards GIT, which every repo has. The same section reserves builds, deploys and remote jobs
# to the user, but those commands belong to a project's own stack: here that rule stays tier 3,
# and a project that wants it detected adds its own PreToolUse hook (docs/guide-install.md).
#
# It never denies: it returns permissionDecision "ask", so the user decides in context. A hard
# block gets disabled at its first false positive; an ask survives.
#
# No external dependencies: the payload is parsed with node when present, and otherwise the raw
# payload is matched. It must NEVER pass silently because parsing failed — a crude match only
# risks an extra prompt, a miss risks a push.
set -uo pipefail

payload=$(cat)

cmd=""
if command -v node >/dev/null 2>&1; then
  cmd=$(printf '%s' "$payload" | node -e '
    let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{
      try{const j=JSON.parse(s);process.stdout.write((j.tool_input&&j.tool_input.command)||"")}
      catch(e){process.stdout.write("")}
    })' 2>/dev/null)
fi
[ -n "$cmd" ] || cmd="$payload"

ask() {
  local reason=${1//\\/\\\\}; reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

# ---- normalize before matching ------------------------------------------------------------------
# Matching the raw string fails both ways: it misses `git -C "<path with spaces>" push`, and it
# fires on `grep "git push"` or on a commit message that quotes the phrase. So quoted runs are
# collapsed to opaque tokens first — EXCEPT after a shell -c, where the quoted string IS the command.
norm=$(printf '%s' "$cmd" | sed -E '
  # a shell invocation executes its quoted argument: unwrap it so it stays guarded
  s/(^|[;&|(]|&&)[[:space:]]*(sh|bash|zsh|pwsh|powershell)([[:space:]]+-[a-zA-Z]+)*[[:space:]]+"([^"]*)"/\1 \4/g
  s/(^|[;&|(]|&&)[[:space:]]*(sh|bash|zsh|pwsh|powershell)([[:space:]]+-[a-zA-Z]+)*[[:space:]]+'"'"'([^'"'"']*)'"'"'/\1 \4/g
  # -C <quoted path> / --git-dir="…": keep the flag, replace the value with a bare token
  s/(-C|--git-dir=|--work-tree=)[[:space:]]*"[^"]*"/\1 QPATH/g
  s/(-C|--git-dir=|--work-tree=)[[:space:]]*'"'"'[^'"'"']*'"'"'/\1 QPATH/g
  # message / pattern arguments are data, never commands
  s/(-m|--message=|--grep=|-F|--pattern|-Pattern)[[:space:]]*"[^"]*"/\1 QARG/g
  s/(-m|--message=|--grep=|-F|--pattern|-Pattern)[[:space:]]*'"'"'[^'"'"']*'"'"'/\1 QARG/g
  # every remaining quoted run is data
  s/"[^"]*"/QSTR/g
  s/'"'"'[^'"'"']*'"'"'/QSTR/g
')
# Two shortcuts, applied PER COMMAND SEGMENT and never to the whole line — `echo x; git push` is
# two commands, and only the first is harmless. The line is split on ; && || | & and newlines;
# a segment that starts with a text tool (it reads its arguments as data and mutates nothing),
# or that asks for --help / -h, is dropped; everything else is matched below.
TEXT_TOOLS='grep|rg|ag|egrep|fgrep|echo|printf|cat|less|head|tail|awk|sed|Select-String|findstr|Get-Content'
norm=$(printf '%s\n' "$norm" | sed -E 's/(\|\||&&|;|\||&)/\n/g' \
  | awk -v tools="^[[:space:](]*(${TEXT_TOOLS})([[:space:]]|\$)" '
      $0 ~ tools { next }
      $0 ~ /(^|[[:space:]])(--help|-h)([[:space:]]|$)/ { next }
      { print }')
[ -n "$norm" ] || exit 0

# A command boundary: start of string, or after ; | & ( or &&.
B='(^|[;&|(]|&&)[[:space:]]*'
# git's global options (-C <path>, -c k=v, --no-pager, --git-dir=…) sit between `git` and its
# subcommand and must be skipped, or only the naked form is guarded. `git.exe` is the Windows form.
G="git(\.exe)?([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--no-pager|--git-dir=[^[:space:]]*|--work-tree=[^[:space:]]*|-P))*[[:space:]]+"
m() { printf '%s' "$norm" | grep -Eq "$1"; }

# ---- 1. the agent stops at the local commit: the push is the user's -----------------------------
m "${B}${G}push" && ask "STOP - the agent stops at the local commit (contract-session § 5). git push is USER-DRIVEN, even when the request sounds like it implies it: the agent commits locally and hands off. Approve only if you explicitly authorized a push this turn."

# ---- 2. shared-worktree hazards: several sessions, ONE git index --------------------------------
# The family is "one command, worktree-wide effect": anything that stages, reverts or deletes by
# scope rather than by pathspec reaches every other session's in-flight files.
m "${B}${G}stash" && ask "DANGER - NEVER 'git stash' in this worktree. It is worktree-WIDE: it sweeps up the uncommitted AND untracked files of every OTHER agent session sharing this tree and pops conflict markers into their files. Commit by pathspec instead."

m "${B}${G}add[[:space:]]+(-A|--all|\.)([[:space:]]|$)" && ask "CAREFUL - 'git add -A/.' stages the WHOLE shared index, including other agents' in-flight files, burying their work in your commit. The rule is explicit pathspecs: git commit -m msg -- <paths>. Approve only if the tree is certainly yours alone."

m "${B}${G}commit[[:space:]]+(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)" && ask "CAREFUL - 'git commit -a' commits every tracked modification in the SHARED worktree, including other agent sessions' in-flight edits. Commit by pathspec instead: git commit -m msg -- <paths>."

m "${B}${G}(checkout|restore)[[:space:]]+(\.|--[[:space:]]+\.)([[:space:]]|$)" && ask "DANGER - 'git checkout .' / 'git restore .' DISCARDS every uncommitted change in the shared worktree, including other agent sessions' work. It is not recoverable via git. Scope it to your own pathspecs."

# -n / --dry-run is the safe way to inspect a clean, and dry-runs are autonomous: not guarded.
if ! printf '%s' "$norm" | grep -Eq "${B}${G}clean([[:space:]]+[^;&|]*)?([[:space:]]-[a-zA-Z]*n|[[:space:]]--dry-run)"; then
  m "${B}${G}clean[[:space:]]+-[a-zA-Z]*[dfx]" && ask "DANGER - 'git clean -fd/-fx' DELETES untracked files across the whole shared worktree - other sessions' scratch work, probes and unstaged new files. Not recoverable. Delete your own files by name instead, or inspect first with 'git clean -nd' (dry-run, unguarded)."
fi

# ---- 3. the STAGED SET, inspected at commit time ------------------------------------------------
# A command-time ask is weak for one hazard: at `git add -A` the cost is invisible, and the harm
# lives in the staged set, which nobody looked at. So at commit time the hook reads what is about
# to be committed, and asks again — naming the folders — if it spans more than one agent's memory
# folder: one folder, one writer (contract-memory § 0).
# Two sources, because git commit has two modes: with a " -- " pathspec the commit takes the
# LISTED paths (read from the raw command — normalization hides quoted runs); without one it
# takes the INDEX (`git diff --cached`, honouring -C <dir>).
# Not covered, declared: co-edits inside ONE shared file, such as a register.
if printf '%s' "$norm" | grep -Eq "${B}${G}commit([[:space:]]|$)"; then
  cdir=$(printf '%s' "$cmd" | sed -nE 's/.*-C[[:space:]]+"([^"]+)".*/\1/p' | head -1)
  [ -n "$cdir" ] || cdir=$(printf '%s' "$cmd" | sed -nE "s/.*-C[[:space:]]+'([^']+)'.*/\1/p" | head -1)
  [ -n "$cdir" ] || cdir=$(printf '%s' "$cmd" | sed -nE 's/.*-C[[:space:]]+([^[:space:]"'"'"']+).*/\1/p' | head -1)
  case "$cmd" in
    *" -- "*) mem_dirs=$(printf '%s' "${cmd##* -- }" | grep -oE '\.critos/memory/a[0-9]+/' | sort -u) ;;
    *)        mem_dirs=$(git ${cdir:+-C "$cdir"} diff --cached --name-only 2>/dev/null | grep -oE '^\.critos/memory/a[0-9]+/' | sort -u) ;;
  esac
  # grep -c always prints a count (0 on no match, exit 1): never add a fallback on top of it.
  n_dirs=$(printf '%s\n' "$mem_dirs" | grep -c '.')
  if [ "${n_dirs:-0}" -gt 1 ]; then
    ask "CAREFUL - this commit spans ${n_dirs} agents' memory folders: $(printf '%s' "$mem_dirs" | tr '\n' ' '). One folder, ONE WRITER (contract-memory § 0): committing another agent's memory buries its in-flight round under your message. Approve ONLY if this is a deliberate structural or migration commit."
  fi
fi

exit 0
