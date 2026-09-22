#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# status-check — the deterministic reconcile: run it BEFORE answering "what is left?".
#
# Read-only. It never rewrites a STATUS (that is /crit-checkpoint); it surfaces the drift and the
# agent acts on it.
#
# Three axes, and all three are needed:
#   1. STATUS vs GIT      what landed since this STATUS was written
#   2. STATUS vs INBOX    what the inbox says is OWED BY YOU (--me <N>; inbox-check.sh)
#   3. ROADMAP rows you LEAD   the shared tier of your plan; a landed row you lead is yours to flip
# Axis 1 cannot see a STATUS that drifted from the inbox rather than from git: that is axis 2.
#
# Usage:  bash ~/.claude/skills/crit-status-check/status-check.sh <memory-folder-or-STATUS-file>...
#                [--me <N>] [--domain <code-path>]...
#   --me N         your agent number; enables axes 2 and 3
#   --domain PATH  scope axis 1 to the code you own (repeatable). Needed in practice: a memory
#                  folder says nothing about which code its agent owns.
#   e.g.  bash ~/.claude/skills/crit-status-check/status-check.sh --me 2 .critos/memory/a2 --domain src/
#
# A project that spans several repos registers them in `.claude/repos` (one path per line,
# relative to this repo's root; '#' comments): axes 2 and 3 are then repeated in each registered
# repo — an entry addressed to you there is owed exactly like one at home. One level only.
set -uo pipefail

ME=""
args=()
DOMAINS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --me) ME="$2"; shift 2 ;;
    --domain) DOMAINS+=("$2"); shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
set -- "${args[@]:-}"

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "status-check: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1

# Which revision of the shared controls produced this output; "+dirty" = may match no release.
# (Stamp duplicated in doc-lint.sh — keep the two in sync.)
ctl_root=$(git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ctl_root" ]; then
  ctl_dirty=""
  [ -n "$(git -C "$ctl_root" status --porcelain -- system skills hooks agents 2>/dev/null | head -1)" ] && ctl_dirty="+dirty"
  echo "### controls: CritOS@$(git -C "$ctl_root" describe --tags --always 2>/dev/null)${ctl_dirty}"
else
  echo "### controls: (unversioned copy — not under git; provenance unknown)"
fi
echo

today=$(date +%Y-%m-%d)

# Infer the agent number from a `.critos/memory/a<N>` argument if --me was not passed.
if [ -z "$ME" ]; then
  for a in "$@"; do
    case "$a" in
      *memory/a[0-9]*) ME=$(basename "${a%/STATUS.md}" | grep -oE '[0-9]+' | head -n1); break ;;
    esac
  done
fi

resolve_status() {   # a STATUS file, a memory folder, or a bare agent folder name (a2)
  local p="$1"
  if [ -f "$p" ]; then echo "$p"; return; fi
  for cand in "$p/STATUS.md" ".critos/memory/$(basename "$p")/STATUS.md"; do
    [ -f "$cand" ] && { echo "$cand"; return; }
  done
}

for arg in "$@"; do
  [ -z "$arg" ] && continue
  sf=$(resolve_status "$arg")
  if [ -z "${sf:-}" ] || [ ! -f "$sf" ]; then
    echo "### $arg — no STATUS file found (looked for $arg, $arg/STATUS.md, .critos/memory/$(basename "$arg")/STATUS.md)"
    echo
    continue
  fi
  if [ -d "$arg" ]; then dr="$arg"; else dr=$(dirname "$sf"); fi
  # last-updated date = the first yyyy-mm-dd on a line mentioning "updated"
  lu=$(grep -iE 'updated' "$sf" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n1)

  echo "### $dr"
  echo "STATUS file : $sf"
  if [ -n "$lu" ]; then
    days=$(( ( $(date -d "$today" +%s) - $(date -d "$lu" +%s) ) / 86400 ))
    echo "Last updated: $lu  (${days}d ago)"
  else
    echo "Last updated: (no yyyy-mm-dd found near 'updated' — cannot date-scope)"
  fi
  echo
  scope=("$dr"); scope_label="$dr"
  if [ ${#DOMAINS[@]} -gt 0 ]; then scope=("${DOMAINS[@]}"); scope_label="${DOMAINS[*]}"; fi
  echo "-- commits touching $scope_label since STATUS was written (it may not reflect these):"
  if [ -n "$lu" ]; then
    log=$(git log --since="$lu" --pretty='  %ad %h %s' --date=short -- "${scope[@]}" 2>/dev/null)
    if [ -n "$log" ]; then echo "$log"
    else echo "  (none)"
    fi
    # A memory-scoped axis is the wrong axis whether or not it is empty: the checkpoint that
    # dates the window is itself a memory commit, so the list is almost never empty.
    case "$scope_label" in
      .critos/memory*)
        if [ ${#DOMAINS[@]} -eq 0 ]; then
          if [ -n "$log" ]; then
            echo "  ^ SUSPECT: this axis is scoped to a MEMORY folder, so the commits above are MEMORY-file commits, not the domain's code — a populated list here reads as an answer and is the wrong axis. Pass --domain <code-path> (repeatable) to scope this axis to what the agent actually owns."
          else
            echo "  ^ SUSPECT: this scope is a MEMORY folder, so \"(none)\" only means no memory file was committed. Pass --domain <code-path> (repeatable) to scope this axis to what the agent actually owns."
          fi
        fi ;;
    esac
  else
    echo "  (skipped — no last-updated date)"
  fi
  echo
  dec="$(dirname "$sf")/DECISIONS.md"
  if [ -f "$dec" ]; then
    echo "-- ADR headers in $dec (reconcile any 'proposed/in-flight' vs the commits above):"
    # The NEWEST 50: the log is append-only, and only the newest entries can still be in flight.
    adr_roll=$(grep -nE '^#{1,4}[[:space:]]*ADR-' "$dec" | sed -E 's/^([0-9]+):#+[[:space:]]*/  L\1  /')
    adr_n=$(printf '%s\n' "$adr_roll" | grep -c .)
    if [ "$adr_n" -gt 50 ]; then
      echo "  (… $((adr_n - 50)) older ADRs not shown — $adr_n total; showing the NEWEST 50)"
    fi
    printf '%s\n' "$adr_roll" | tail -n 50
    echo
  fi
done

# ---- axis 2: what the INBOX says is owed by you ------------------------------------------------
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -n "$ME" ]; then
  echo "### inbox — [OPEN] handoffs ADDRESSED TO YOU (AGENT $ME)"
  bash "$here/inbox-check.sh" --me "$ME"
  echo
else
  echo "### inbox — SKIPPED (no agent id)."
  echo "  Pass --me <N> (or a path like .critos/memory/a<N>) to reconcile against the shared inbox."
  echo "  WITHOUT THIS you are answering 'what's left' from git alone — which cannot see"
  echo "  what another agent is waiting on YOU for. Re-run with --me."
  echo
fi

# (Registry parser duplicated in doc-lint.sh — keep the two in sync.)
constellation() {   # the repos registered in $1/.claude/repos, one absolute path per line
  local f="$1/.claude/repos" line
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$line" ] && continue
    case "$line" in /*|[A-Za-z]:*) printf '%s\n' "$line" ;; *) printf '%s\n' "$1/$line" ;; esac
  done < "$f"
}
if [ -n "$ME" ]; then
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    echo "### inbox — constellation repo: $(basename "$r")"
    if [ ! -d "$r" ]; then
      echo "  (registered in .claude/repos but MISSING on disk: $r)"
      echo
      continue
    fi
    (cd "$r" && bash "$here/inbox-check.sh" --me "$ME")
    echo
  done < <(constellation "$root")
fi

# ---- axis 3: open ROADMAP rows you lead, here and in every registered repo ----------------------
# The answer to "what is on your plan?" has three labelled buckets: [OWED] (axis 2), [SHARED]
# (printed here), [DOMAIN] (your own STATUS). Struck rows and settled statuses are skipped.
if [ -n "$ME" ]; then
  echo "### roadmap — open items YOU lead (AGENT $ME) — the [SHARED] tier of your plan"
  rm_out=$( { printf '%s\n' "$root"; constellation "$root"; } | while IFS= read -r rr; do
    [ -d "$rr" ] || continue
    rmf="$rr/.critos/shared/ROADMAP.md"
    [ -f "$rmf" ] || continue
    awk -F'|' -v me="$ME" -v src="$(basename "$rr")" '
      $2 ~ /^[[:space:]]*R[0-9]+[[:space:]]*$/ {
        id=$2; dev=$3; lead=$4; status=$5
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",id); gsub(/^[[:space:]]+|[[:space:]]+$/,"",lead)
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",status)
        if (lead !~ ("(^|[^0-9A-Za-z])A(GENT)?[ ]*" me "([^0-9]|$)")) next
        # The settled marker is anchored at the start of the status CELL (as in doc-lint [6]):
        # an open status may mention a settled leg.
        if (status ~ /^(✅|⏸|done|deferred|parked|closed|superseded|dropped)/) next
        gsub(/\*\*/,"",dev); gsub(/^[[:space:]]+|[[:space:]]+$/,"",dev)
        if (length(dev) > 150) dev = substr(dev,1,150) "…"
        printf "  %s [%s] (lead: %s, %s) %s\n", id, status, lead, src, dev
      }' "$rmf"
  done )
  if [ -n "$rm_out" ]; then echo "$rm_out"; else echo "  (none open with you as lead — or no ROADMAP register found)"; fi
  echo
fi

echo "Now reconcile, then answer:"
echo "  1. For each commit above — is it reflected in STATUS? If a build shows landed, it is DONE."
echo "  2. For each ADR marked proposed/in-flight — do the commits show it already landed?"
echo "  3. For each inbox entry addressed to you — it is OWED BY YOU. Never report one as"
echo "     'blocked on others' without reading it: they may have answered and be waiting on you."
echo "  4. Answer 'what's left' FORWARD-ONLY and in THREE LABELED BUCKETS — never a flat mix:"
echo "       [OWED]   the inbox entries above (close or ACK them)"
echo "       [SHARED] the roadmap items above (named efforts; propose new rows via HANDOFFS)"
echo "       [DOMAIN] your STATUS worksheet intentions (micro-steps; the how is yours)"
echo "  5. FACT-FLIP now: any STATUS claim DISPROVED by the evidence above (a landed commit, an"
echo "     absorbed inbox entry) gets corrected on the spot — date + proof ref, commit it. Do NOT"
echo "     report 'already closed, STATUS doesn't know yet' and leave the lie in the file."
echo "     SAME for a roadmap row above that you KNOW is landed: flip it (your register) or send"
echo "     the steward the one-line flip proposal with proof — THIS session, not at checkpoint."
echo "     Anything beyond a fact-flip (re-narrating, re-planning) stays /crit-checkpoint's rewrite."
