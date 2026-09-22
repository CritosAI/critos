#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# CritOS installer (Linux) - prepares the MACHINE. Run once per machine, from this checkout:
#     bash install.sh
#
# It does NOT install CritOS into a project: that is /crit-scaffold-project, run inside the
# target repo. Delivery is hybrid: the machine provides the TOOLCHAIN (shared from this
# checkout, so keep the folder where it is), each project PINS its own copy of the contracts.
#
#   --claude-home <dir>   install into another folder instead of ~/.claude (a sandbox, for tests)
#   --uninstall           remove everything this installer manages, and nothing else
#
# What it manages, and nothing beyond it (the same four things as install.ps1 on Windows):
#   <ClaudeHome>/skills/crit-*     one symlink per skill (the folder itself stays yours)
#   <ClaudeHome>/hooks/critos      a symlink to this checkout's hooks
#   <ClaudeHome>/settings.json     ONE PreToolUse entry, the guard (a backup is written first)
#   <ClaudeHome>/CLAUDE.md         ONE block, between the CritOS markers
#
# Idempotent: what is already correct is left untouched. Restart Claude Code afterward.
# Needs: bash, git, node (settings.json is JSON, and node is a requirement of the checks anyway).
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_home="$HOME/.claude"
uninstall=0
while [ $# -gt 0 ]; do
  case "$1" in
    --claude-home) claude_home="${2%/}"; shift 2 ;;
    --uninstall)   uninstall=1; shift ;;
    *) echo "install: unknown argument $1" >&2; exit 2 ;;
  esac
done
is_default=0; [ "$claude_home" = "$HOME/.claude" ] && is_default=1

skills_src="$repo/skills"
hooks_src="$repo/hooks"
skills_dst="$claude_home/skills"
hooks_dst="$claude_home/hooks"
hook_link="$hooks_dst/critos"
guard_name="guard-user-driven-actions.sh"
if [ "$is_default" = 1 ]; then hook_cmd="bash ~/.claude/hooks/critos/$guard_name"
else                           hook_cmd="bash \"$hook_link/$guard_name\""; fi

begin_tag="<!-- BEGIN CritOS (managed) -->"
end_tag="<!-- END CritOS (managed) -->"
settings_path="$claude_home/settings.json"
claude_md="$claude_home/CLAUDE.md"

command -v node >/dev/null 2>&1 || { echo "install: node is required (settings.json is JSON)" >&2; exit 2; }

warn() { echo "WARNING: $*" >&2; }

set_link() {   # $1 = link, $2 = target, $3 = label
  local link="$1" target="$2" label="$3" current
  if [ -e "$link" ] || [ -L "$link" ]; then
    if [ ! -L "$link" ]; then
      warn "  $label exists and is NOT a symlink - left untouched (move it aside first)."
      return
    fi
    current="$(readlink "$link")"
    if [ "${current%/}" = "${target%/}" ]; then
      echo "  ok        $label  (already correct)"
      return
    fi
    rm "$link"
  fi
  ln -s "$target" "$link"
  echo "  symlink   $label"
}

assert_real_folder() {   # $1 = path, $2 = label. A whole-folder link here would put everything anyone writes into it inside this checkout.
  if [ -L "$1" ]; then
    echo "install: $2 is a SYMLINK, not a folder. Remove the link (rm \"$1\" removes the link, never its target) and run the installer again." >&2
    exit 2
  fi
  mkdir -p "$1"
}

# settings.json through node: $1 = add|remove|has, $2 = the settings path, $3 = the hook command.
# `has` exits 0 when an entry with that command is registered. `add` and `remove` write a
# backup first (settings.json.bak-critos) and print nothing.
settings() {
  node - "$1" "$2" "$3" <<'NODE'
const [mode, file, cmd] = process.argv.slice(2);
const fs = require("fs");
let s = {};
if (fs.existsSync(file)) { const raw = fs.readFileSync(file, "utf8"); if (raw.trim()) s = JSON.parse(raw); }
const pre = (s.hooks && Array.isArray(s.hooks.PreToolUse)) ? s.hooks.PreToolUse.filter(Boolean) : [];
const isGuard = (e) => Array.isArray(e.hooks) && e.hooks.some((h) => h && h.command === cmd);
if (mode === "has") process.exit(pre.some(isGuard) ? 0 : 1);
if (mode === "add") {
  if (pre.some(isGuard)) process.exit(0);
  s.hooks = s.hooks || {};
  s.hooks.PreToolUse = pre.concat([{ matcher: "Bash|PowerShell",
    hooks: [{ type: "command", command: cmd, timeout: 10, statusMessage: "CritOS guard: checking user-driven actions..." }] }]);
} else if (mode === "remove") {
  if (!pre.some(isGuard)) process.exit(0);
  s.hooks.PreToolUse = pre.filter((e) => !isGuard(e));
} else { process.exit(2); }
if (fs.existsSync(file)) fs.copyFileSync(file, file + ".bak-critos");
fs.writeFileSync(file, JSON.stringify(s, null, 2) + "\n");
NODE
}

# --- which revision is being installed -------------------------------------------------------
rev="$(git -C "$repo" describe --tags --always --dirty 2>/dev/null || true)"
tag="$(git -C "$repo" describe --tags --exact-match 2>/dev/null || true)"
echo "CritOS checkout: $repo"
if [ -n "$tag" ]; then echo "  release   $tag"
else
  echo "  revision  $rev"
  warn "  this checkout is NOT at a release tag: you are installing an unreleased revision (fine for development and pilots; a project should run a release)."
fi
echo

if [ "$uninstall" = 1 ]; then
  if [ -d "$skills_dst" ]; then
    for d in "$skills_dst"/crit-*; do
      [ -L "$d" ] || continue
      rm "$d" && echo "  removed   skills/$(basename "$d")"
    done
  fi
  if [ -L "$hook_link" ]; then rm "$hook_link" && echo "  removed   hooks/critos"; fi
  if [ -f "$settings_path" ] && settings has "$settings_path" "$hook_cmd"; then
    settings remove "$settings_path" "$hook_cmd"
    echo "  removed   the guard entry from settings.json (backup: settings.json.bak-critos)"
  fi
  if [ -f "$claude_md" ] && grep -qF "$begin_tag" "$claude_md" && grep -qF "$end_tag" "$claude_md"; then
    node -e '
const fs = require("fs"); const [file, b, e] = process.argv.slice(1);
const cur = fs.readFileSync(file, "utf8"); const bi = cur.indexOf(b), ei = cur.indexOf(e);
if (bi >= 0 && ei > bi) {
  const out = (cur.slice(0, bi).replace(/\s+$/, "") + "\n" + cur.slice(ei + e.length).replace(/^\s+/, "")).trim();
  fs.writeFileSync(file, out ? out + "\n" : "");
}' "$claude_md" "$begin_tag" "$end_tag"
    echo "  removed   the CritOS block from CLAUDE.md"
  fi
  echo
  echo "CritOS removed from this machine. Projects keep their pinned contracts; their controls are gone."
  exit 0
fi

mkdir -p "$claude_home"

# --- skills: one symlink per skill -----------------------------------------------------------
assert_real_folder "$skills_dst" "skills"
shipped=()
for s in "$skills_src"/crit-*/; do
  s="${s%/}"; [ -d "$s" ] || continue
  shipped+=("$(basename "$s")")
  set_link "$skills_dst/$(basename "$s")" "$s" "skills/$(basename "$s")"
done
# A skill this checkout no longer ships leaves a link pointing at nothing: remove it.
for d in "$skills_dst"/crit-*; do
  [ -L "$d" ] || continue
  name="$(basename "$d")"; keep=0
  for s in "${shipped[@]}"; do [ "$s" = "$name" ] && keep=1; done
  [ "$keep" = 1 ] || { rm "$d" && echo "  removed   skills/$name  (no longer shipped)"; }
done

# --- hooks: one symlink, in a folder of its own ----------------------------------------------
assert_real_folder "$hooks_dst" "hooks"
set_link "$hook_link" "$hooks_src" "hooks/critos"

# --- settings.json: register the guard. A guard that is installed and not registered guards
# nothing, and looks exactly like one that does.
if settings has "$settings_path" "$hook_cmd"; then
  echo "  ok        settings.json (the guard is registered)"
else
  had=0; [ -f "$settings_path" ] && had=1
  settings add "$settings_path" "$hook_cmd"
  if [ "$had" = 1 ]; then echo "  updated   settings.json (the guard registered as a PreToolUse hook; backup: settings.json.bak-critos)"
  else                    echo "  created   settings.json (the guard registered as a PreToolUse hook)"; fi
fi

# --- CLAUDE.md: a single file that may hold your own content -> MERGE one block, never link ---
node - "$claude_md" "$repo/global/CLAUDE.global.md" "$begin_tag" "$end_tag" <<'NODE'
const [file, globalFile, b, e] = process.argv.slice(2);
const fs = require("fs");
const block = b + "\n" + fs.readFileSync(globalFile, "utf8").replace(/\s+$/, "") + "\n" + e;
if (!fs.existsSync(file)) { fs.writeFileSync(file, block + "\n"); console.log("  created   CLAUDE.md"); process.exit(0); }
const cur = fs.readFileSync(file, "utf8");
const bi = cur.indexOf(b), ei = cur.indexOf(e);
if (bi >= 0 && ei > bi) {
  const out = cur.slice(0, bi) + block + cur.slice(ei + e.length);
  if (out === cur) console.log("  ok        CLAUDE.md (block already current)");
  else { fs.writeFileSync(file, out); console.log("  updated   CLAUDE.md (CritOS block replaced)"); }
} else {
  fs.writeFileSync(file, cur.replace(/\s+$/, "") + "\n\n" + block + "\n");
  console.log("  appended  the CritOS block to CLAUDE.md");
}
NODE

echo
echo "Machine ready. This checkout is now a permanent dependency: $repo"
echo "Moving the folder breaks every control - run the installer again if you do."
echo "To update: fetch, check out the new release tag, run the installer again."
echo "Restart Claude Code, then run /crit-scaffold-project inside a repo: see docs/guide-install.md"
