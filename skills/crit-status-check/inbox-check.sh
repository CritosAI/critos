#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# inbox-check — the second reconcile axis: what the shared inbox says is owed BY YOU.
#
# The inbox outranks the snapshot: "what do I owe?" is a query, never a recall. A STATUS can
# drift from the inbox without drifting from git, and no git-based check can see that.
# Entries are read WHOLE, never grep-snippeted: a long single-line entry rendered as an omitted
# match is exactly the entry you needed.
#
# Read-only. It surfaces what is owed; the agent acts on it.
#
# Usage: bash inbox-check.sh --me <N> [--inbox <path>] [--stale-days <N>] [--all]
#   --me N          your agent number (accepts "1" or "A1")
#   --inbox PATH    override the inbox (default: .critos/shared/HANDOFFS.md)
#   --stale-days N  flag entries older than N days that were never ACKed (default 4)
#   --all           list every live [OPEN] in the inbox, not just yours
set -uo pipefail

ME=""; INBOX=""; STALE_DAYS=4; SHOW_ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --me)         ME="$2"; shift 2 ;;
    --inbox)      INBOX="$2"; shift 2 ;;
    --stale-days) STALE_DAYS="$2"; shift 2 ;;
    --all)        SHOW_ALL=1; shift ;;
    *) shift ;;
  esac
done

[ -n "$ME" ] || { echo "inbox-check: --me <agent-number> is required"; exit 1; }
ME="${ME#[Aa]}"

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "inbox-check: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1

[ -z "$INBOX" ] && [ -f .critos/shared/HANDOFFS.md ] && INBOX=.critos/shared/HANDOFFS.md
[ -n "${INBOX:-}" ] && [ -f "$INBOX" ] || {
  echo "### inbox — no HANDOFFS.md found (looked in .critos/shared/). Pass --inbox <path>."
  exit 0
}

# A retired inbox is a signpost, not a channel (first line carries ⚰ or RETIRED): say so, rather
# than print a zero that reads like a clean inbox.
if head -1 "$INBOX" | grep -qE '⚰|RETIRED'; then
  echo "INBOX: $INBOX — ⚰ RETIRED — not a channel. Nothing here is owed, counted, or writable:"
  echo "  do not post to it, and do not read it expecting work. (Its head says where the live one is.)"
  exit 0
fi

# NOTE: no apostrophes inside the awk program — it sits in a single-quoted shell string.
awk -v me="$ME" -v today="$(date +%Y-%m-%d)" -v stale_days="$STALE_DAYS" \
    -v inbox="$INBOX" -v show_all="$SHOW_ALL" '
# An entry has exactly ONE owner: an agent named in a parenthetical ("(+A5 FYI)") is copied, not
# responsible. Same rule as doc-lint check [5].
function owner(s) { sub(/\(.*/, "", s); return s }
# day-number from Y-M-D (no mktime, so no gawk dependency)
function jdn(s,   y, m, d, a) {
  y = substr(s,1,4) + 0; m = substr(s,6,2) + 0; d = substr(s,9,2) + 0
  a = int((14 - m) / 12); y = y + 4800 - a; m = m + 12*a - 3
  return d + int((153*m + 2)/5) + 365*y + int(y/4) - int(y/100) + int(y/400) - 32045
}
function flush(   head, colon, rest, p, tok, participants, cnt, P, sender, rcpt, mine, age, i) {
  if (n == 0) return
  head = buf[0]
  colon = index(head, ":")

  # 1. The lifecycle token is read ONLY at its syntactic position: the first "[" after the colon,
  #    allowing a short decorative lead (whitespace, bold markers, a parenthetical, a non-ASCII
  #    symbol) and never prose — an entry that merely QUOTES "[OPEN]" is not open. The unbolded
  #    form is accepted: fail LIVE (count it) and let doc-lint [7] name the format defect.
  rest = substr(head, colon + 1)
  if (match(rest, /^([ \t*_~]|\([^)]*\)|[^ -~])*\[/)) { p = RSTART + RLENGTH - 1 } else { n = 0; return }
  if (p == 0) { n = 0; return }
  tok = substr(rest, p + 1, 24)
  if (tok !~ /^OPEN/ && tok !~ /^PARKED-OWNED/) { n = 0; return }
  total_open++

  # 2. participants sit before the first colon, split on the arrow (U+2192, not ">")
  participants = (colon > 0) ? substr(head, 1, colon - 1) : head
  cnt = split(participants, P, "→")
  if (cnt < 2) { n = 0; return }
  sender = owner(P[1])
  rcpt   = owner(P[cnt])

  # 3. an entry you SENT is never owed by you, even when addressed to ALL
  if (sender ~ ("AGENT[ ]*" me "([^0-9]|$)")) { n = 0; sent_by_me++; return }

  mine = 0
  if (rcpt ~ ("AGENT[ ]*" me "([^0-9]|$)")) mine = 1
  if (rcpt ~ ("A" me "([^0-9]|$)"))         mine = 1
  if (rcpt ~ /ALL/)                          mine = 1
  if (!mine && !show_all) { n = 0; return }

  age = jdn(today) - jdn(entry_date)
  if (mine) {
    mine_count++
    if (age >= stale_days) stale_count++
    printf "\n--- [%d] %s  (%dd old)%s\n", mine_count, entry_date, age, \
           (age >= stale_days ? "   *** STALE — never ACKed ***" : "")
  } else {
    printf "\n--- (not yours) %s\n", entry_date
  }
  for (i = 0; i < n; i++) print buf[i]
  n = 0
}
/^- [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] / {
  flush(); entry_date = substr($0, 3, 10); n = 0
}
{ if (entry_date != "") buf[n++] = $0 }
END {
  flush()
  printf "\n============================================================\n"
  printf "INBOX: %s\n", inbox
  printf "  live [OPEN]/[PARKED] entries in the inbox : %d\n", total_open
  printf "  ADDRESSED TO YOU (AGENT %s)               : %d\n", me, mine_count
  printf "  of those, STALE (>=%sd, never ACKed)      : %d\n", stale_days, stale_count
  printf "  (sent BY you, awaiting others — not yours : %d)\n", sent_by_me
  if (mine_count == 0) {
    printf "\n  Nothing is owed by you in the inbox. THIS is the answer to \"what do I owe\" —\n"
    printf "  not what your STATUS remembers.\n"
  } else {
    printf "\n  ^^ These are OWED BY YOU. Do NOT report them as \"blocked on others\" without\n"
    printf "  reading each: the other agent may have already answered and be waiting on YOU.\n"
    printf "  Close each with an [ABSORBED ... by A%s] flip or a one-line ACK.\n", me
  }
}
' "$INBOX"
