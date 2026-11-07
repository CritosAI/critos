#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# guard-inbox — a PreToolUse hook, the second of the guard's family. It turns one rule of
# contract-session § 5 into a control: a surface several sessions write — the shared inbox,
# `.critos/shared/HANDOFFS.md` — is written and committed only when its uncommitted diff is ONE
# actor's, yours.
#
# The actors of a diff of the inbox, read from the entry grammar (contract-shared § 1) — every
# CHANGED line to its hand, an unchanged line to nobody, whatever its head:
#   a NEW entry        `- YYYY-MM-DD — AGENT N → …`      its sender, N
#   a FLIPPED entry    the same head, another body        its recipient, M — only the recipient flips
#   a NEW sub-line     `  - YYYY-MM-DD — AGENT K: …`     the agent it names, K
# Entries share a head — a day, a sender, a recipient — as often as an agent writes twice in a
# day: a line is matched whole first, and only a line absent from the old text is read by its head.
#
# Two edges, one predicate:
#   the WRITE    Edit, Write, MultiEdit on the inbox, or a shell command that would write it: the
#                actors of the uncommitted diff plus the actor of the write in progress — more
#                than one, the guard asks and names whose lines it saw.
#   the COMMIT   `git commit` carrying the inbox, by pathspec (the working tree) or from the index
#                (the staged diff): more than one actor, the guard asks — the commit would carry a
#                neighbour's entry under your message. The escape when the neighbour does not
#                commit: stage your own hunk only and commit WITHOUT a pathspec — the staged diff
#                is yours and passes; the guard asks instead when that index stages any other path.
#
# It never denies: it returns permissionDecision "ask", so the user decides in context.
# Declared bound: entry lines only — a carry of prose outside an entry (a head edit) is not seen,
# and a flip by a non-recipient reads as the recipient's; a `sed` without -i is a read, as the
# other text tools are, and a redirection behind a text tool is not seen. Without node the
# payload is read crudely and the guard errs toward asking, never toward passing.
set -uo pipefail

payload=$(cat)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

ask() {
  local reason=${1//\\/\\\\}; reason=${reason//\"/\\\"}
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

# ---- the payload --------------------------------------------------------------------------------
tool=""; fpath=""; cmd=""; kind="none"; crude=0
: > "$tmp/old"; : > "$tmp/new"
if command -v node >/dev/null 2>&1; then
  printf '%s' "$payload" | node -e '
    const fs = require("fs"); const dir = process.argv[1]; let s = "";
    process.stdin.on("data", d => s += d).on("end", () => {
      let j = {}; try { j = JSON.parse(s) } catch (e) { j = {} }
      const t = j.tool_input || {};
      fs.writeFileSync(dir + "/tool", j.tool_name || "");
      fs.writeFileSync(dir + "/path", t.file_path || "");
      fs.writeFileSync(dir + "/cmd", t.command || "");
      let o = "", n = "", k = "none";
      if (Array.isArray(t.edits)) { k = "edit"; for (const e of t.edits) { o += (e.old_string || "") + "\n"; n += (e.new_string || "") + "\n"; } }
      else if (typeof t.content === "string") { k = "write"; n = t.content; }
      else if (typeof t.new_string === "string") { k = "edit"; o = t.old_string || ""; n = t.new_string; }
      fs.writeFileSync(dir + "/kind", k);
      fs.writeFileSync(dir + "/old", o); fs.writeFileSync(dir + "/new", n);
    })' "$tmp" 2>/dev/null
  tool=$(cat "$tmp/tool" 2>/dev/null); fpath=$(cat "$tmp/path" 2>/dev/null)
  cmd=$(cat "$tmp/cmd" 2>/dev/null); kind=$(cat "$tmp/kind" 2>/dev/null)
fi
if [ -z "$tool" ]; then
  # No node, or an unreadable payload: the tool's name and the inbox's name are read from the raw
  # text, nothing finer — a crude read risks an extra prompt, a miss risks a carry.
  case "$payload" in *HANDOFFS.md*) ;; *) exit 0 ;; esac
  tool=$(printf '%s' "$payload" | grep -oE '"tool_name"[[:space:]]*:[[:space:]]*"[A-Za-z]+"' | head -1 | sed -E 's/.*"([A-Za-z]+)"$/\1/')
  crude=1
fi

# ---- helpers ------------------------------------------------------------------------------------
INBOX_REL=".critos/shared/HANDOFFS.md"
is_inbox_path() { printf '%s' "$1" | tr '\\' '/' | grep -Eq '(^|/)\.critos/shared/HANDOFFS\.md$'; }
# the inbox of the repo that holds the folder $1; empty when there is none
inbox_of() {
  local r; r=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 0
  [ -f "$r/$INBOX_REL" ] && printf '%s' "$r/$INBOX_REL"
}
# actors_between OLD NEW — the hands a change from OLD to NEW carries: `<N>\t<what>` per line.
# OLD is read whole first; NEW is the main pass. An entry line found verbatim in OLD is unchanged,
# whatever its head. A line absent from OLD is read by its head — its text up to the first colon,
# the day and the participants, shared by every entry an agent writes to one recipient in a day:
# per head, the appeared lines replace the vanished ones first (flips, the recipient's), and the
# rest are new entries (the sender's). The identity (OLD = NEW) is nobody's hand.
actors_between() {
  awk -v OLD="$1" '
    function agent(s) { if (match(s, /AGENT [0-9]+/)) return substr(s, RSTART + 6, RLENGTH - 6); return "" }
    function head(s,  i) { i = index(s, ":"); return (i ? substr(s, 1, i) : s) }
    function recipient(s,  i) { i = index(s, "→"); return (i ? agent(substr(s, i)) : "") }
    BEGIN {
      E = "^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] — AGENT [0-9]+ → "
      S = "^[ \t]+- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] — AGENT [0-9]+:"
      while ((getline l < OLD) > 0) { if (l ~ E) oldline[l]++; else if (l ~ S) subold[l] = 1 }
      close(OLD)
    }
    $0 ~ E { if ($0 in oldline) { seen[$0]++; next }
             appeared[head($0)]++; next }
    $0 ~ S { if (!($0 in subold)) { a = agent($0); if (a != "") printf "%s\ta sub-line\n", a } }
    END {
      for (l in oldline) { d = oldline[l] - ((l in seen) ? seen[l] : 0); if (d > 0) vanished[head(l)] += d }
      for (h in appeared) {
        f = (h in vanished) ? vanished[h] : 0; if (f > appeared[h]) f = appeared[h]
        if (f > 0) { a = recipient(h); if (a != "") printf "%s\ta flipped token\n", a }
        if (appeared[h] - f > 0) { a = agent(h); if (a != "") printf "%s\ta new entry\n", a }
      }
    }
  ' "$2" | sort -u
}
head_of() {   # $1 = inbox path -> the committed version into $tmp/head (empty when not in HEAD)
  local r; r=$(git -C "$(dirname "$1")" rev-parse --show-toplevel 2>/dev/null)
  git -C "$r" show "HEAD:$INBOX_REL" > "$tmp/head" 2>/dev/null || : > "$tmp/head"
}
describe() {   # stdin: `<N>\t<what>` lines -> "AGENT N (what), AGENT M (what)"
  awk -F'\t' '{ n[$1] = (n[$1] ? n[$1] ", " : "") $2 } END { s = ""; for (k in n) s = s (s ? "; " : "") "AGENT " k " (" n[k] ")"; print s }'
}
count_agents() { cut -f1 | sort -u | grep -c '.'; }
# split_segments — stdin: the command; stdout: one segment per line, cut at ; | & && || and at a
# newline OUTSIDE quotes only. A quoted run keeps its text and its quotes, so a commit message
# holding a separator does not cut, and the pathspec read below is the same, quoted or not; a
# quoted run spanning lines is joined with a space. A backslash escapes the next character.
split_segments() {
  awk '
    { s = $0; n = length(s)
      for (i = 1; i <= n; i++) { c = substr(s, i, 1)
        if (q == "") {
          if (c == "\"" || c == "\047") { q = c; out = out c }
          else if (c == "\\") { out = out c substr(s, i + 1, 1); i++ }
          else if (c == ";" || c == "|" || c == "&") { print out; out = "" }
          else out = out c
        } else {
          out = out c
          if (c == q) q = ""
          else if (q == "\"" && c == "\\") { out = out substr(s, i + 1, 1); i++ }
        }
      }
      if (q == "") { print out; out = "" } else out = out " "
    }
    END { if (out != "") print out }
  '
}

# ---- the write edge: the editing tools ----------------------------------------------------------
case "$tool" in
  Edit|Write|MultiEdit)
    is_inbox_path "$fpath" || exit 0
    inbox=$(inbox_of "$(dirname "$fpath")"); [ -n "$inbox" ] || exit 0
    head_of "$inbox"
    actors_between "$tmp/head" "$inbox" > "$tmp/uncommitted"
    if [ "$crude" = 1 ]; then
      [ -s "$tmp/uncommitted" ] && ask "CAREFUL - the shared inbox already carries an uncommitted hand ($(describe < "$tmp/uncommitted")), and this write could not be read (node is not available). A surface several sessions write is written only when its uncommitted diff is one actor's, yours (contract-session § 5). Approve only if that hand is yours."
      exit 0
    fi
    case "$kind" in
      write) actors_between "$inbox" "$tmp/new" ;;
      *)     actors_between "$tmp/old" "$tmp/new" ;;
    esac > "$tmp/write"
    n=$(cat "$tmp/uncommitted" "$tmp/write" | count_agents)
    if [ "${n:-0}" -gt 1 ]; then
      ask "CAREFUL - two hands on the shared inbox: uncommitted $(describe < "$tmp/uncommitted"); this write $(describe < "$tmp/write"). A surface several sessions write is written only when its uncommitted diff is one actor's, yours (contract-session § 5): a commit of this file would carry the neighbour's line under your message. Approve only if every hand named is yours."
    fi
    exit 0 ;;
  Bash|PowerShell|"") ;;
  *) exit 0 ;;
esac

# ---- the shells: the commit edge, and a shell write ---------------------------------------------
[ -n "$cmd" ] || cmd="$payload"
case "$cmd" in *HANDOFFS.md*|*"git commit"*|*"git.exe commit"*|*" commit "*) ;; *) exit 0 ;; esac
cdir=$(printf '%s' "$cmd" | sed -nE 's/.*-C[[:space:]]+"([^"]+)".*/\1/p' | head -1)
[ -n "$cdir" ] || cdir=$(printf '%s' "$cmd" | sed -nE "s/.*-C[[:space:]]+'([^']+)'.*/\1/p" | head -1)
[ -n "$cdir" ] || cdir=$(printf '%s' "$cmd" | sed -nE 's/.*-C[[:space:]]+([^[:space:]"'"'"']+).*/\1/p' | head -1)
inbox=$(inbox_of "${cdir:-.}"); [ -n "$inbox" ] || exit 0
root=$(dirname "$(dirname "$(dirname "$inbox")")")

TEXT_TOOLS='grep|rg|ag|egrep|fgrep|echo|printf|cat|less|head|tail|awk|Select-String|findstr|Get-Content|diff|wc'
printf '%s\n' "$cmd" | split_segments | while IFS= read -r seg; do
  seg=$(printf '%s' "$seg" | sed -E 's/^[[:space:](]+//')
  [ -n "$seg" ] || continue
  printf '%s' "$seg" | grep -Eq "^(${TEXT_TOOLS})([[:space:]]|\$)" && continue
  # sed reads unless it edits in place: -i, --in-place, or an i in a cluster of short options
  if printf '%s' "$seg" | grep -Eq '^sed([[:space:]]|$)'; then
    printf '%s' "$seg" | grep -Eq '(^|[[:space:]])(-[a-zA-Z]*i|--in-place)' || continue
  fi
  if printf '%s' "$seg" | grep -Eq '^git(\.exe)?([[:space:]]+(-C[[:space:]]+[^[:space:]]+|-c[[:space:]]+[^[:space:]]+|--no-pager|--git-dir=[^[:space:]]*|--work-tree=[^[:space:]]*|-P))*[[:space:]]+commit([[:space:]]|$)'; then
    head_of "$inbox"
    case "$seg" in
      *" -- "*)
        printf '%s' "${seg##* -- }" | grep -q 'HANDOFFS.md' || continue
        actors_between "$tmp/head" "$inbox" > "$tmp/carry"
        n=$(count_agents < "$tmp/carry")
        [ "${n:-0}" -gt 1 ] && ask "CAREFUL - this commit takes the shared inbox from the working tree, and that file carries two hands: $(describe < "$tmp/carry"). Your commit would carry a neighbour's entry under your message (contract-session § 5). Escape: stage your own hunk only and commit WITHOUT a pathspec, with nothing else staged. Approve only if every hand named is yours." ;;
      *)
        git -C "$root" diff --cached --name-only 2>/dev/null > "$tmp/staged"
        grep -qx "$INBOX_REL" "$tmp/staged" || continue
        others=$(grep -vx "$INBOX_REL" "$tmp/staged" | head -3 | paste -sd' ' -)
        [ -n "$others" ] && ask "CAREFUL - a commit without a pathspec carries everything the shared index holds: beside the inbox it stages $others. The escape for a shared inbox is your own hunk ALONE (contract-session § 5) - commit the other paths first, by pathspec, or unstage them. Approve only if every staged path is yours."
        git -C "$root" show ":$INBOX_REL" > "$tmp/index" 2>/dev/null || : > "$tmp/index"
        actors_between "$tmp/head" "$tmp/index" > "$tmp/carry"
        n=$(count_agents < "$tmp/carry")
        [ "${n:-0}" -gt 1 ] && ask "CAREFUL - the staged inbox carries two hands: $(describe < "$tmp/carry"). Your commit would carry a neighbour's entry under your message (contract-session § 5). Stage your own hunk only. Approve only if every hand named is yours." ;;
    esac
    continue
  fi
  printf '%s' "$seg" | grep -Eq '^git(\.exe)?([[:space:]]|$)' && continue
  printf '%s' "$seg" | grep -q 'HANDOFFS.md' || continue
  # a shell write of the inbox: its hand cannot be read, so an uncommitted hand already there is
  # enough to ask — a commit after it would carry both
  head_of "$inbox"
  actors_between "$tmp/head" "$inbox" > "$tmp/uncommitted"
  [ -s "$tmp/uncommitted" ] && ask "CAREFUL - the shared inbox already carries an uncommitted hand ($(describe < "$tmp/uncommitted")), and a shell write adds one the guard cannot read. A surface several sessions write is written only when its uncommitted diff is one actor's, yours (contract-session § 5). Commit or stage the neighbour's hunk first, or write with Edit so the guard can read your line. Approve only if that hand is yours."
done

exit 0
