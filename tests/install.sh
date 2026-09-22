#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The installer, on the platform this runs on: install.ps1 under Git Bash on Windows, install.sh
# elsewhere - into a sandbox home, never the real one. What it must prove:
#   install     one link per shipped skill, the hooks link, the guard registered, the block merged
#   again       idempotent: every line says already correct / registered / current, no byte moves
#   yours       a settings.json with your own hook and a CLAUDE.md with your own text keep both
#   uninstall   removes exactly what it created: your hook and your text stay
#   refuse      a skills folder that is a link is refused, and nothing is written
#     bash tests/install.sh
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
ok()   { echo "ok    install  $1"; }
bad()  { echo "FAIL  install  $1"; fail=1; }

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) win=1 ;;
  *) win=0 ;;
esac
run_installer() {   # $1 = sandbox home, $2... = extra args (--uninstall)
  local home="$1"; shift
  if [ "$win" = 1 ]; then
    local args=(-ClaudeHome "$(cygpath -w "$home")"); [ "${1:-}" = "--uninstall" ] && args+=(-Uninstall)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$repo/install.ps1")" "${args[@]}" 2>&1
  else
    bash "$repo/install.sh" --claude-home "$home" "$@" 2>&1
  fi
}
is_link() { if [ "$win" = 1 ]; then [ -d "$1" ] && fsutil reparsepoint query "$(cygpath -w "$1")" >/dev/null 2>&1; else [ -L "$1" ]; fi; }
make_link() { if [ "$win" = 1 ]; then cmd //c mklink //J "$(cygpath -w "$1")" "$(cygpath -w "$2")" >/dev/null; else ln -s "$2" "$1"; fi; }

shipped=$(ls -d "$repo"/skills/crit-*/ | wc -l | tr -d ' ')
home="$tmp/home"; mkdir -p "$home"

# yours: seed the sandbox with the user's own settings hook and CLAUDE.md text
printf '{ "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "bash mine.sh" } ] } ] }, "theme": "dark" }\n' > "$home/settings.json"
printf '# my own conventions\n\nkeep this line\n' > "$home/CLAUDE.md"

# install
out="$(run_installer "$home")"; rc=$?
links=0; for d in "$home"/skills/crit-*; do is_link "$d" && links=$((links+1)); done
if [ "$rc" = 0 ] && [ "$links" = "$shipped" ]; then ok "one link per shipped skill ($links)"; else bad "install (exit $rc): $links links for $shipped skills"; printf '%s\n' "$out" | sed 's/^/        /'; fi
if is_link "$home/hooks/critos" && [ -f "$home/hooks/critos/guard-user-driven-actions.sh" ]; then ok "hooks/critos resolves to the guard"; else bad "hooks/critos"; fi
if grep -q "guard-user-driven-actions.sh" "$home/settings.json"; then ok "the guard is registered"; else bad "the guard is not in settings.json"; fi
if grep -q '"bash mine.sh"' "$home/settings.json" && grep -q '"theme"' "$home/settings.json"; then ok "your own hook and settings kept"; else bad "settings.json lost your content"; cat "$home/settings.json" | sed 's/^/        /'; fi
if [ -f "$home/settings.json.bak-critos" ]; then ok "a backup was written first"; else bad "no settings.json.bak-critos"; fi
if grep -q "BEGIN CritOS (managed)" "$home/CLAUDE.md" && grep -q "END CritOS (managed)" "$home/CLAUDE.md" && grep -q "keep this line" "$home/CLAUDE.md"; then ok "the block merged, your text kept"; else bad "CLAUDE.md"; sed 's/^/        /' "$home/CLAUDE.md"; fi

# again
before="$(cat "$home/settings.json" "$home/CLAUDE.md")"
out="$(run_installer "$home")"; rc=$?
after="$(cat "$home/settings.json" "$home/CLAUDE.md")"
n_ok=$(printf '%s\n' "$out" | grep -c "already correct")
if [ "$rc" = 0 ] && [ "$n_ok" = "$((shipped + 1))" ] && printf '%s' "$out" | grep -q "the guard is registered" && printf '%s' "$out" | grep -q "block already current" && [ "$before" = "$after" ]; then ok "idempotent (second run changed nothing)"; else bad "second run: $n_ok 'already correct' for $((shipped + 1)) links, or a byte moved"; printf '%s\n' "$out" | sed 's/^/        /'; fi

# uninstall
out="$(run_installer "$home" --uninstall)"; rc=$?
left=0; for d in "$home"/skills/crit-*; do [ -e "$d" ] && left=$((left+1)); done
if [ "$rc" = 0 ] && [ "$left" = 0 ] && [ ! -e "$home/hooks/critos" ]; then ok "uninstall removed every link"; else bad "uninstall (exit $rc): $left links left"; printf '%s\n' "$out" | sed 's/^/        /'; fi
if ! grep -q "guard-user-driven-actions.sh" "$home/settings.json" && grep -q '"bash mine.sh"' "$home/settings.json"; then ok "the guard entry removed, your hook kept"; else bad "settings.json after uninstall"; sed 's/^/        /' "$home/settings.json"; fi
if ! grep -q "BEGIN CritOS" "$home/CLAUDE.md" && grep -q "keep this line" "$home/CLAUDE.md"; then ok "the block removed, your text kept"; else bad "CLAUDE.md after uninstall"; sed 's/^/        /' "$home/CLAUDE.md"; fi
[ -d "$repo/skills/crit-doc-lint" ] && ok "the checkout is intact (a link was removed, never its target)" || bad "the checkout lost a skill folder"

# refuse: a skills folder that is itself a link
home2="$tmp/home2"; mkdir -p "$home2" "$tmp/elsewhere"; make_link "$home2/skills" "$tmp/elsewhere"
out="$(run_installer "$home2")"; rc=$?
if [ "$rc" != 0 ] && [ ! -e "$home2/settings.json" ] && [ ! -e "$home2/CLAUDE.md" ]; then ok "refuses a skills folder that is a link, writes nothing"; else bad "a linked skills folder was accepted (exit $rc)"; printf '%s\n' "$out" | sed 's/^/        /'; fi

exit $fail
