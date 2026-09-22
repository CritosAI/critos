#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# doc-lint — the deterministic documentation-hygiene battery (the steward's mechanical pass).
#
# The battery. This header is part of the interface: update it WITH the checks.
#   [1] BROKEN            a relative markdown link that does not resolve to an existing file
#   [2] PATH-IN-CODE      a top-level `doc/….md` path hard-coded in code (reference by ID or
#                         concept, never by path)
#   [3] ORPHAN            a tracked .md that no other tracked .md links to ([1] and [3] are the
#                         two halves of the "no floating doc" rule)
#   [4] DANGLING-SKILL    a /skill-name referenced in the skill layer that is not installed
#   [5] INBOX hygiene     ping-pong topics, [OPEN] entries with no "Done when:", diffused
#                         ownership (inbox-audit.mjs)
#   [6] STALE-Rx          an open ROADMAP row untouched for >=10 days
#   [7] BAD-TOKEN         an inbox lifecycle token outside the closed vocabulary (token-audit.mjs)
#   [8] STATUS-CHRONICLE  (WARN) a STATUS.md over the line budget or stacking dated AS-OF sections
#   [9] STALE-STATUS      a STATUS.md whose last commit is >=14 days old
#  [10] DANGLING-WIKI-LINK (WARN) a [[slug]] that resolves nowhere the repo can reach
#  [11] TIER-3-LESSON     an accepted_rule that does not name its "Enforcement: tier-N"
#  [12] UNROTATED-LOG     (WARN) an append-only memory log past the skimmable budget
#  [13] MEMORY-SHAPE      a `.critos/memory/` child that is not `a<N>`, or an `a<N>` folder that
#                         no roster row maps (contract-memory § 0)
#  [14] PIN-DRIFT         a pinned `.critos/system/` file that differs from its DECLARED
#                         release's entry in `releases.manifest` (never compared to HEAD);
#       VERSION-SPLIT     a repo registered in `.claude/repos` whose pinned tier declares another
#                         release than this one (a migration covers the declared project)
#  [15] DEFINITION-PATH   a .md path or an absolute path in an agent definition (contract-agent § 1)
#  [16] RETIRED-REF       a live doc whose link resolves to a file whose first line carries the
#                         ⚰/RETIRED marker
#  [17] COLD-LIVE-TOKEN   an [OPEN]/[PARKED-OWNED] token in an ENTRY of a HANDOFFS archive
#  [18] DEFINITION-SHAPE  an agent definition whose ## sections differ from the template's
#  [19] DEFINITION-ACTOR  a definition naming an actor other than itself (contract-agent § 1)
#  [20] SHELF-INDEX       a rostered Shelf address that does not resolve, or a README-indexed
#                         shelf folder holding tracked .md its index chain never links
#  [21] CITED-ID          a decision or lesson id cited in a doc, a register or code that no
#                         DECISIONS / LESSONS-LEARNED log declares, archives included
#
# A project that spans several repos registers them in `.claude/repos`; the whole battery is then
# repeated in each (one level, read-only).
#
# Two rules every check follows: a check that could not run says SKIPPED, never "(none)" — a
# zero produced by a broken pipeline is not evidence; and every finding is a FLAG for its owner,
# never a gate. Interpretive audits (redundancy, real drift, taxonomy) are not in scope.
#
# Usage:  bash ~/.claude/skills/crit-doc-lint/doc-lint.sh
set -uo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "doc-lint: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1

# ---- layout ------------------------------------------------------------------------------------
INBOX=""; ROSTER=""; RMF=""
[ -f .critos/shared/HANDOFFS.md ] && INBOX=.critos/shared/HANDOFFS.md
[ -f .critos/project/agents.md ]  && ROSTER=.critos/project/agents.md
[ -f .critos/shared/ROADMAP.md ]  && RMF=.critos/shared/ROADMAP.md
# A retired inbox stays on disk as a signpost (first line carries ⚰ or RETIRED): it is not a
# channel and counts toward nothing.
inbox_retired=""
if [ -n "$INBOX" ] && head -1 "$INBOX" | grep -qE '⚰|RETIRED'; then
  inbox_retired="$INBOX"; INBOX=""
fi
mem_files() { git ls-files ".critos/memory/*/$1" 2>/dev/null | sort -u; }

if [ -d .critos ]; then
  _ver=$(grep -hoE '"system"[^,]*' .critos/system/VERSION 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?' | head -1)
  echo "### layout: .critos/ — system ${_ver:-?}"
elif [ -f system/VERSION ] && [ -f releases.manifest ]; then
  echo "### layout: this repo is CritOS itself (it publishes its system tier, it does not install it)"
else
  echo "### layout: NONE — no CritOS layer found in this repo (only the repo-wide checks can run)"
fi
[ -n "$inbox_retired" ] && echo "### (a ⚰ RETIRED inbox exists: $inbox_retired — a signpost, not a channel; it counts toward nothing)"

# ---- which controls ran -----------------------------------------------------------------------
# The controls are shared from a CritOS checkout: say which revision ran, and whether that
# checkout was dirty — "+dirty" means this output may match no release.
# (Stamp duplicated in status-check.sh — keep the two in sync.)
ctl_root=$(git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ctl_root" ]; then
  ctl_rev=$(git -C "$ctl_root" describe --tags --always 2>/dev/null)
  ctl_dirty=""
  [ -n "$(git -C "$ctl_root" status --porcelain -- system skills hooks agents 2>/dev/null | head -1)" ] && ctl_dirty="+dirty"
  echo "### controls: CritOS@${ctl_rev}${ctl_dirty}"
else
  echo "### controls: (unversioned copy — not under git; provenance unknown)"
fi
echo

# ---- shared helpers ---------------------------------------------------------------------------
# A link is markdown syntax OUTSIDE code: fenced blocks and backtick spans are stripped first.
strip_code() { awk '/^[[:space:]]*```/{f=!f;next} !f{gsub(/``[^`]*``/,""); gsub(/`[^`]*`/,""); print}' "$1"; }
links_of()   { strip_code "$1" | grep -oE '\]\([^)#][^)]*\)' 2>/dev/null | sed -E 's/^\]\(//; s/\)$//'; }
# Untracked .md are link SOURCES too: a new doc's links are checked while its author is looking.
md_link_sources() { { git ls-files '*.md'; git ls-files --others --exclude-standard -- '*.md'; } | sort -u; }
# The repos this one registers in `.claude/repos`, one absolute path per line.
constellation() {
  local f="$1/.claude/repos" line
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(printf '%s' "$line" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$line" ] && continue
    case "$line" in /*|[A-Za-z]:*) printf '%s\n' "$line" ;; *) printf '%s\n' "$1/$line" ;; esac
  done < "$f"
}
decode() { local u="$1"; u=${u//%20/ }; u=${u//%28/(}; u=${u//%29/)}; u=${u//%26/&}; u=${u//%27/\'}; printf '%s' "$u"; }

echo "### doc-lint [1] — broken relative links in .md (existence-checked per link; tracked + untracked)"
any_broken=0
while IFS= read -r f; do
  d=$(dirname "$f")
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
    u=${url%%#*}; [ -z "$u" ] && continue
    u=$(decode "$u")
    if [ ! -e "$d/$u" ]; then
      echo "BROKEN  $f  ->  $url"
      any_broken=1
    fi
  done < <(links_of "$f")
done < <(md_link_sources)
[ "$any_broken" = 0 ] && echo "(none — all relative links resolve)"

echo
echo "### doc-lint [2] — top-level doc/*.md paths hard-coded in code (fragile breadcrumbs)"
# Excluded: a doc co-located with its code (`…/doc/…`), archived code, this skill itself, and
# any line annotated `doc-lint:allow path-in-code` — for a path that is a program's I/O target.
# The failure signal is stderr: a no-match batch already makes xargs+grep exit non-zero.
p2_err=$(mktemp)
p2_raw=$(git ls-files -z '*.js' '*.mjs' '*.ts' '*.py' '*.sql' '*.yaml' '*.yml' \
    | xargs -0 grep -nE '(^|[^/[:alnum:]])doc/[A-Za-z0-9._/-]+\.md' 2>"$p2_err")
if [ -s "$p2_err" ]; then
  echo "SKIPPED — grep/xargs wrote errors: $(head -2 "$p2_err" | tr '\n' ' ')"
  echo "          (cannot judge path-in-code; this is NOT a clean none)"
  rm -f "$p2_err"
else
  rm -f "$p2_err"
  p2_hits=$(printf '%s\n' "$p2_raw" \
    | grep -vE '^[^:]*(/doc/|/archive/)[^:]*:' \
    | grep -vE '(^|/)skills/crit-doc-lint/' \
    | grep -v 'doc-lint:allow path-in-code' || true)
  if [ -n "$p2_hits" ]; then printf '%s\n' "$p2_hits" | sed 's/^/PATH-IN-CODE  /'; else echo "(none)"; fi
fi

echo
echo "### doc-lint [3] — ORPHAN docs: tracked .md that nothing links to (the 'no floating doc' rule)"
# The reachability graph is built from TRACKED sources only: an uncommitted pointer can vanish.
targets=$(mktemp)
while IFS= read -r f; do
  d=$(dirname "$f")
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
    u=${url%%#*}; [ -z "$u" ] && continue
    realpath -m --relative-to=. "$d/$(decode "$u")" 2>/dev/null
  done < <(links_of "$f")
done < <(git ls-files '*.md') | sort -u > "$targets"
# Exempt: docs found by CONVENTION — entry points, the memory triad, the three registers, the
# pinned tier's own files, per-entity notes. A repo declares its own convention families in
# `.claude/doc-lint-exempt` (one extended regex per line, matched against the path).
exempt_re=""
[ -f .claude/doc-lint-exempt ] && \
  exempt_re=$(grep -vE '^[[:space:]]*(#|$)' .claude/doc-lint-exempt | paste -sd'|' -)
any_orphan=0
while IFS= read -r f; do
  case "$(basename "$f")" in
    README.md|CLAUDE.md|CLAUDE.global.md|AGENTS.md|SKILL.md|MEMORY.md) continue ;;
    STATUS.md|DECISIONS.md|LESSONS-LEARNED.md) continue ;;
    HANDOFFS.md|ROADMAP.md|CONTRACTS.md|VERSION|CHANGELOG.md) continue ;;
  esac
  case "$f" in .critos/memory/*/notes/*) continue ;; esac
  if [ -n "$exempt_re" ] && printf '%s\n' "$f" | grep -qE "$exempt_re"; then continue; fi
  grep -qxF "$f" "$targets" || { echo "ORPHAN  $f  (no tracked .md points at it — register it in its index, or archive it)"; any_orphan=1; }
done < <(git ls-files '*.md')
rm -f "$targets"
[ "$any_orphan" = 0 ] && echo "(none — every doc is reachable from an index)"

echo
echo "### doc-lint [4] — DANGLING skill references in the agentic docs"
# Installed = the machine's skills + the repo's own + the ones bundled with Claude Code (not on
# disk). Scope: the skill layer only (SKILL.md files and CLAUDE.md) — the text the model reads to
# choose a skill; elsewhere a /token is usually a URL or an API path.
# In the CritOS repository itself, the skills it ships count as present.
own_skills=""; [ -f system/VERSION ] && [ -f releases.manifest ] && own_skills=skills
installed=$( { ls -1 ~/.claude/skills 2>/dev/null; ls -1 .claude/skills 2>/dev/null; [ -n "$own_skills" ] && ls -1 "$own_skills" 2>/dev/null; } | sed 's#/##' | sort -u)
builtins="config hooks clear compact help agents rewind model init review resume
run verify code-review simplify loop schedule artifact-design dataviz claude-api
security-review update-config keybindings-help deep-research fewer-permission-prompts"
any_dangling=0
scan=$(git ls-files '*.md' | grep -E '(SKILL\.md$|^CLAUDE\.md$)' | grep -v '/crit-doc-lint/' || true)
for f in $scan; do
  # An invocation is backtick-delimited AND kebab-case (`/crit-doc-lint`), or follows an invoking
  # verb ("use /name"); a single backticked word is usually a URL path segment.
  for tok in $( { grep -oE '`/[a-z][a-z0-9]*(-[a-z0-9]+)+`' "$f" 2>/dev/null;
                  grep -oiE '\b(use|run|invoke|via|see) /[a-z][a-z0-9]*(-[a-z0-9]+)*([^A-Za-z0-9/_-]|$)' "$f" 2>/dev/null; } \
               | grep -oE '/[a-z][a-z0-9-]*' | sed 's#^/##' | sort -u); do
    printf '%s\n' "$installed" | grep -qxF "$tok" && continue
    printf '%s\n' $builtins | grep -qxF "$tok" && continue
    echo "DANGLING-SKILL  $f  ->  /$tok  (referenced, but no such skill is installed)"
    any_dangling=1
  done
done
[ "$any_dangling" = 0 ] && echo "(none — every /skill referenced is installed)"

echo
echo "### doc-lint [5] — INBOX hygiene (ping-pong · no closure criterion · diffused ownership)"
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
inbox="$INBOX"
if [ -n "$inbox_retired" ] && [ -z "$inbox" ]; then
  echo "(inbox ⚰ RETIRED: $inbox_retired — not a channel; audit skipped)"
elif [ -z "$inbox" ]; then
  echo "(no HANDOFFS inbox in this repo — skipped)"
elif ! command -v node >/dev/null 2>&1; then
  echo "(node not available — inbox audit skipped; the other checks ran)"
else
  node "$here/inbox-audit.mjs" "$inbox" $(ls .critos/shared/archive/HANDOFFS-archive-*.md 2>/dev/null)
fi

echo
echo "### doc-lint [6] — STALE-Rx: open ROADMAP rows nobody has touched in >=10 days"
# The net under the lead's flip duty. A flagged row is not "done": re-verify it with its lead;
# re-verifying touches the row, which resets its clock.
rmf="$RMF"
if [ -z "$rmf" ]; then
  echo "(no ROADMAP register in this repo — skipped)"
else
  blame_tmp=$(mktemp)
  git blame --line-porcelain -- "$rmf" 2>/dev/null | awk '/^committer-time /{t=$2} /^\t/{print t "\t" substr($0,2)}' > "$blame_tmp"
  if [ ! -s "$blame_tmp" ]; then
    echo "SKIPPED — git blame produced no output for $rmf (uncommitted register? shallow clone?)."
    echo "          (cannot judge Rx staleness; this is NOT a clean none)"
    rm -f "$blame_tmp"
    rmf=""
  fi
fi
if [ -n "$rmf" ]; then
  any_stale_rx=0
  now=$(date +%s)
  while IFS= read -r bl; do
    ts=${bl%%	*}; line=${bl#*	}
    printf '%s' "$line" | grep -qE '^\|[[:space:]]*R[0-9]+[[:space:]]*\|' || continue
    # Read the STATUS CELL (the last non-empty one), never the whole row, and anchor the settled
    # marker at its start: a row's prose may contain "done" while the row is open. An unknown
    # or empty cell counts as OPEN.
    status=$(printf '%s' "$line" | awk -F'|' '{ for (i=NF; i>0; i--) { gsub(/^[ \t]+|[ \t]+$/,"",$i); if ($i != "") { print $i; exit } } }')
    printf '%s' "$status" | grep -qiE '^(✅|⏸|done|deferred|parked|closed|superseded|dropped)' && continue
    age=$(( (now - ts) / 86400 ))
    if [ "$age" -ge 10 ]; then
      id=$(printf '%s' "$line" | grep -oE '^\|[[:space:]]*R[0-9]+' | grep -oE 'R[0-9]+')
      lead=$(printf '%s' "$line" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/,"",$4); print $4}')
      echo "STALE-Rx  $rmf: $id (lead: $lead) — untouched for ${age}d. Re-verify with the lead: is it still truly open?"
      any_stale_rx=1
    fi
  done < "$blame_tmp"
  rm -f "$blame_tmp"
  [ "$any_stale_rx" = 0 ] && echo "(none — every open Rx row was touched in the last 10 days)"
fi

echo
echo "### doc-lint [7] — BAD-TOKEN: inbox entries whose lifecycle token is outside the closed vocabulary"
# The owed-counter treats only OPEN and PARKED-OWNED as live: an ask written under an invented
# token is owed by someone and counted by nobody.
if [ -n "$inbox_retired" ] && [ -z "$inbox" ]; then
  echo "(inbox ⚰ RETIRED: $inbox_retired — not a channel; audit skipped)"
elif [ -z "$inbox" ]; then
  echo "(no HANDOFFS inbox in this repo — skipped)"
elif ! command -v node >/dev/null 2>&1; then
  echo "(node not available — token audit skipped; the other checks ran)"
else
  node "$here/token-audit.mjs" "$inbox"
fi

echo
echo "### doc-lint [8] — STATUS-CHRONICLE (WARN): a memory STATUS.md that stopped being a snapshot"
# A STATUS is overwritten, not prepended. Two fingerprints of a chronicle: over the line budget
# (default 200; a repo may set its own in `.claude/doc-lint-status-lines`, one integer), or more
# than one dated AS-OF heading (extra heading words: `.claude/doc-lint-status-headings`).
status_max=200
[ -f .claude/doc-lint-status-lines ] && status_max=$(grep -oE '^[0-9]+' .claude/doc-lint-status-lines | head -1)
: "${status_max:=200}"
status_files=$(mem_files STATUS.md)
if [ -z "$status_files" ]; then
  echo "(no memory STATUS.md in this repo — skipped)"
fi
any_chronicle=0
[ -n "$status_files" ] && while IFS= read -r sf; do
  n=$(grep -c '' "$sf")
  asof_re='AS[ -]OF|SESSION (CLOSE|END)|CURRENT STATE'
  [ -f .claude/doc-lint-status-headings ] && \
    asof_re="$asof_re|$(grep -vE '^[[:space:]]*(#|$)' .claude/doc-lint-status-headings | paste -sd'|' -)"
  asof=$(grep -cE "^#{1,4}[[:space:]].*($asof_re)[^A-Za-z]*[0-9]{4}-[0-9]{2}-[0-9]{2}" "$sf")
  if [ "$n" -gt "$status_max" ] || [ "$asof" -gt 1 ]; then
    echo "STATUS-CHRONICLE  $sf — ${n} lines (budget ${status_max}), ${asof} dated AS-OF sections."
    echo "                  A STATUS is OVERWRITTEN, not prepended: keep what is TRUE NOW, let git hold the history."
    any_chronicle=1
  fi
done <<< "$status_files"
[ -n "$status_files" ] && [ "$any_chronicle" = 0 ] && echo "(none — every STATUS reads as a snapshot)"

echo
echo "### doc-lint [9] — STALE-STATUS: a memory STATUS.md nobody has touched in >=14 days"
# The flag means "re-verify with the owner", never "this is wrong": a STATUS legitimately rests
# while its domain is quiet.
any_stale_status=0
now9=$(date +%s)
if [ -z "$status_files" ]; then
  echo "(no memory STATUS.md in this repo — skipped)"
else
  while IFS= read -r sf; do
    ct=$(git log -1 --format=%ct -- "$sf" 2>/dev/null)
    [ -z "$ct" ] && continue
    age=$(( (now9 - ct) / 86400 ))
    if [ "$age" -ge 14 ]; then
      echo "STALE-STATUS  $sf — last commit ${age}d ago. Re-verify with its owner: is this still true?"
      any_stale_status=1
    fi
  done <<< "$status_files"
  [ "$any_stale_status" = 0 ] && echo "(none — every STATUS was touched in the last 14 days)"
fi

echo
echo "### doc-lint [10] — DANGLING-WIKI-LINK (WARN): a [[slug]] that resolves nowhere reachable"
# A slug resolves if it is (a) a heading or ID declared in a tracked .md, (a2) a tracked doc's
# basename, (a3) a token-shaped first cell of a table row, (b) a machine-local auto-memory note
# name, or (c) exempted in `.claude/doc-lint-exempt`. WARN: namespace (b) lives outside the
# repo. Archives are records and are not scanned; this skill's own docs quote the syntax.
wl_tmp=$(mktemp); wl_declared=$(mktemp)
git grep -hoE '\[\[[A-Za-z0-9][A-Za-z0-9._-]*\]\]' -- '*.md' ':(exclude)*archive*' ':(exclude)*skills/crit-doc-lint/*' 2>/dev/null \
  | sed -E 's/^\[\[//; s/\]\]$//' | sort -u > "$wl_tmp"
if [ ! -s "$wl_tmp" ]; then
  echo "(no [[slug]] links in this repo — skipped)"
  rm -f "$wl_tmp" "$wl_declared"
else
{
  git grep -hoE '^#{1,6}[[:space:]]+[A-Za-z0-9][A-Za-z0-9._-]*' -- '*.md' 2>/dev/null \
    | sed -E 's/^#+[[:space:]]+//'
  # NUL-delimited: a file name may contain spaces.
  git ls-files -z '*.md' 2>/dev/null | while IFS= read -r -d '' p; do b=${p##*/}; printf '%s\n' "${b%.md}"; done
  git grep -hoE '^\|[[:space:]]*~{0,2}[A-Za-z][A-Za-z0-9._-]{0,23}~{0,2}[[:space:]]*\|' -- '*.md' 2>/dev/null \
    | sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|$//; s/~~//g'
  ls -1 ~/.claude/projects/*/memory/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//'
} | sort -u > "$wl_declared"
any_wl=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  grep -qxF "$s" "$wl_declared" && continue
  if [ -n "$exempt_re" ] && printf '%s\n' "$s" | grep -qE "$exempt_re"; then continue; fi
  where=$(git grep -l -F "[[$s]]" -- '*.md' 2>/dev/null | head -3 | tr '\n' ' ')
  echo "DANGLING-WIKI-LINK  [[$s]] — declared nowhere reachable. Cited in: $where"
  any_wl=1
done < "$wl_tmp"
rm -f "$wl_tmp" "$wl_declared"
[ "$any_wl" = 0 ] && echo "(none — every [[slug]] resolves)"
fi

echo
echo "### doc-lint [11] — TIER-3 LESSON: an accepted_rule that does not name its enforcement tier"
# A lessons log is written as headings (`## L-A<N>-NNN …`) or as top-level bullets
# (`- **YYYY-MM-DD · accepted_rule — …`): the shape is detected first, because a bullet boundary
# inside a heading-shaped file would split entries at their own lists. The field is read at its
# syntactic position — a line that STARTS with it — never anywhere in the body.
tier3_out=$(
  mem_files LESSONS-LEARNED.md | while IFS= read -r lf; do
      [ -f "$lf" ] || continue
      shape=headings
      [ "$( { grep -cE '^#{1,4}[[:space:]]+.*(L-[A-Za-z0-9]+-[0-9]|[0-9]{4}-[0-9]{2}-[0-9]{2})' "$lf" || true; } 2>/dev/null)" = 0 ] && shape=bullets
      awk -v f="$lf" -v shape="$shape" '
        function flush(   t) {
          if (hdr == "") return
          if (acc && d == "") { undated++; hdr = ""; return }
          if (acc && !has) {
            t = hdr; sub(/^[#-]+[[:space:]]*/, "", t)
            printf "TIER-3-LESSON  %s:%d  %s\n", f, ln, substr(t, 1, 96)
          }
          hdr = ""
        }
        function isBoundary() {
          if (shape == "headings") return ($0 ~ /^#{1,4}[[:space:]]/)
          return ($0 ~ /^- /)
        }
        isBoundary() && (shape == "bullets" || /L-[A-Za-z0-9]+-[0-9]/ || /[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
          flush()
          hdr = $0; ln = NR; acc = ($0 ~ /accepted_rule/); has = 0
          d = (match($0, /[0-9]{4}-[0-9]{2}-[0-9]{2}/)) ? substr($0, RSTART, RLENGTH) : ""
          next
        }
        hdr != "" { if ($0 ~ /accepted_rule/) acc = 1; if ($0 ~ /^[[:space:]]*(-[[:space:]]+)?[*_]{0,2}[Ee]nforcement:/) has = 1 }
        END {
          flush()
          if (undated > 0) printf "UNDATED-LESSON %s — %d accepted_rule entr%s skipped (no date)\n", f, undated, (undated == 1 ? "y" : "ies")
        }
      ' "$lf"
    done
)
if [ -n "$tier3_out" ]; then
  printf '%s\n' "$tier3_out"
  echo "               → each: add \"Enforcement: tier-N\" (1 impossible · 2 detected deterministically · 3 written-and-hoped),"
  echo "                 and for tier 3 say why no detector is possible."
else
  echo "(none — every accepted_rule names its enforcement tier)"
fi

echo
echo "### doc-lint [12] — UNROTATED LOG: an append-only memory log past the skimmable budget"
# The remedy is rotation, never deletion (default budget 1200 lines; a repo may set its own in
# `.claude/doc-lint-log-lines`). Rotation is forbidden while the entries that would move are
# still cited, so a log may DECLARE its overage in its own head — the state word
# `DECLARED EXEMPTION — ACTIVE`, case-sensitive — and is then reported, never silent.
log_max=1200
[ -f .claude/doc-lint-log-lines ] && log_max=$(grep -oE '^[0-9]+' .claude/doc-lint-log-lines | head -1)
: "${log_max:=1200}"
logs12() { mem_files DECISIONS.md; mem_files LESSONS-LEARNED.md; }
any_unrotated=0
while IFS= read -r lg; do
  [ -f "$lg" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  n=$(grep -c '' "$lg")
  [ "$n" -gt "$log_max" ] || continue
  ents=$( { grep -cE '^#{1,4}[[:space:]]*(ADR|D|L)-' "$lg" || true; } 2>/dev/null)
  if head -n 60 "$lg" | grep -qE 'DECLARED EXEMPTION[^A-Za-z]{0,8}ACTIVE'; then
    why=$(head -n 60 "$lg" | grep -E 'DECLARED EXEMPTION[^A-Za-z]{0,8}ACTIVE' | head -1 | sed -E 's/^[>[:space:]*#]*//; s/\*\*//g' | cut -c1-150)
    echo "DECLARED-OVER  $lg — ${n} lines (budget ${log_max}), ${ents} entries — exemption declared in the log head."
    echo "               → ${why}"
    continue
  fi
  echo "UNROTATED-LOG  $lg — ${n} lines (budget ${log_max}), ${ents} entries."
  echo "               → Rotate: move the oldest entries to archive/$(basename "${lg%.md}")-archive-<period>.md and leave a pointer."
  echo "                 Append-only means never DELETE; it does not mean never MOVE. This file is in an onboarding read-path."
  any_unrotated=1
done < <(logs12)
# Aging by status (contract-memory § 2): an entry marked fully superseded or completed is
# archivable whatever the line count. An info line, not a finding; "superseded in part" is not.
while IFS= read -r lg; do
  [ -f "$lg" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  arch=$( { grep -cE '^\*\*Status[^*]*\*\*:?.*(superseded by|completed [0-9]{4})' "$lg" || true; } 2>/dev/null)
  [ "${arch:-0}" -gt 0 ] && echo "ARCHIVABLE     $lg — ${arch} entr$( [ "$arch" = 1 ] && echo y || echo ies) marked fully superseded/completed still in the live log (aging trigger 1, contract-memory §2 — the owner archives, or A1 will)"
done < <(logs12)
[ "$any_unrotated" = 0 ] && echo "(none — every append-only memory log is within budget, or declares its overage in its own head)"

echo
echo "### doc-lint [13] — MEMORY-SHAPE: one agent, one folder, one writer, one address"
if [ -d .critos/memory ]; then
  any_shape=0
  for d in .critos/memory/*/; do
    [ -d "$d" ] || continue
    b=$(basename "$d")
    case "$b" in
      a[0-9]|a[0-9][0-9]) ;;
      *) echo "MEMORY-SHAPE  .critos/memory/$b — not an agent folder. The address IS the owner (a<N>); a folder named otherwise cannot be attributed by structure and falls back to a roster grep that can drift."; any_shape=1; continue ;;
    esac
    [ -n "$ROSTER" ] || continue
    n=${b#a}
    grep -qE "^\|[[:space:]]*(A)?${n}[[:space:]]*\|" "$ROSTER" \
      || { echo "MEMORY-SHAPE  .critos/memory/$b exists but no row for A${n} in $ROSTER — an unrostered writer is an owner nobody can route to."; any_shape=1; }
  done
  [ "$any_shape" = 0 ] && echo "(none — every memory folder is a<N> and every one of them is rostered)"
else
  echo "(no .critos/memory/ in this repo — skipped)"
fi

echo
echo "### doc-lint [14] — PIN-DRIFT: the pinned system tier vs its declared release"
# The target is the DECLARED version's entries in the release manifest, never HEAD: a project
# pinned at an older release verifies against its own release. A release candidate
# (`1.2.0-rc.1`) is a version of its own, with its own entries. The manifest is found from where
# this control lives — the project keeps no pointer to CritOS.
if [ ! -f .critos/system/VERSION ]; then
  if [ -f system/VERSION ] && [ -f releases.manifest ]; then
    echo "(this repo is CritOS itself — its system is the release, nothing pinned; skipped)"
  else
    echo "(no pinned system tier in this repo — skipped)"
  fi
else
  pv=$(grep -oE '"system"[^,]*' .critos/system/VERSION 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?' | head -1)
  mf14=""
  [ -n "$ctl_root" ] && [ -f "$ctl_root/system/VERSION" ] && [ ! -f "$ctl_root/.critos/system/VERSION" ] \
    && [ -f "$ctl_root/releases.manifest" ] && mf14="$ctl_root/releases.manifest"
  if [ -z "$pv" ]; then
    echo "SKIPPED — .critos/system/VERSION carries no x.y.z version (cannot verify; NOT a clean none)"
  elif [ -z "$mf14" ]; then
    echo "SKIPPED — the controls do not run from a CritOS checkout, so no release manifest sits beside them (cannot verify pin ${pv}; NOT a clean none)"
  elif ! awk -v v="$pv" '$1 == v { f = 1 } END { exit !f }' "$mf14"; then
    echo "SKIPPED — version ${pv} has no entries in the release manifest (cannot verify; NOT a clean none)"
  else
    any_drift=0
    while read -r v14 h14 f14; do
      if [ ! -f ".critos/system/$f14" ]; then
        echo "PIN-DRIFT  .critos/system/$f14 — MISSING (release ${pv} ships it)"
        any_drift=1
      elif [ "$(git hash-object ".critos/system/$f14" 2>/dev/null)" != "$h14" ]; then
        echo "PIN-DRIFT  .critos/system/$f14 — differs from release ${pv}. The tier is not editable in-project: a local edit is overwritten SILENTLY by the next migration (contract-system §2). Restore the pin, or raise the change as a method amendment."
        any_drift=1
      fi
    done < <(awk -v v="$pv" '$1 == v' "$mf14")
    [ "$any_drift" = 0 ] && echo "(pin intact — .critos/system/ matches release ${pv} byte-for-byte, $(awk -v v="$pv" '$1 == v' "$mf14" | grep -c .) files)"
  fi
  # Second predicate, VERSION-SPLIT: a migration covers the project as it is declared
  # (contract-system § 6), so a registered repo that pins a tier must declare THIS repo's release.
  # Each repo's own pin check verifies it against the release it declares and cannot see the
  # split. Read from the hub only — one level, never from a child run.
  if [ -n "$pv" ] && [ -z "${DOC_LINT_CHILD:-}" ]; then
    while IFS= read -r r14; do
      [ -n "$r14" ] && [ -f "$r14/.critos/system/VERSION" ] || continue
      sv=$(grep -oE '"system"[^,]*' "$r14/.critos/system/VERSION" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?' | head -1)
      [ "$sv" = "$pv" ] && continue
      echo "VERSION-SPLIT  $(basename "$r14") declares ${sv:-no version}, this repo declares ${pv} — a migration covers every repo the project declares, in the same round (contract-system § 6): migrate the satellite too."
    done < <(constellation "$root")
  fi
fi

echo
echo "### doc-lint [15] — DEFINITION-PATH: a path in an agent definition, beyond the law-fixed addresses"
# Only the two classes that are wrong without judgment: a .md path (a doc map) and an absolute
# path (a machine, not a perimeter). Perimeter-versus-interior depth is the steward's review.
def_files=$(git ls-files '.critos/project/agents/agent-*.md' '.claude/agents/agent-*.md' 2>/dev/null)
if [ -z "$def_files" ]; then
  echo "(no agent definitions in this repo — skipped)"
else
  any_defpath=0
  while IFS= read -r df; do
    [ -f "$df" ] || continue
    while IFS= read -r tok; do
      [ -z "$tok" ] && continue
      case "$tok" in
        .critos/memory/a[0-9]*/|.critos/memory/a[0-9]*) continue ;;   # the law-fixed memory address
        .critos/shared/HANDOFFS.md) continue ;;                       # the law-fixed inbox address
        http://*|https://*) continue ;;
      esac
      printf '%s' "$tok" | grep -qiE '\.md$|^[a-z]:/|^/(home|users)/' || continue
      echo "DEFINITION-PATH  $df  ->  $tok"
      any_defpath=1
    done < <(grep -oE '[A-Za-z0-9_.~<>-]*/[A-Za-z0-9_.~<>/*-]+' "$df" | sort -u)
  done <<< "$def_files"
  [ "$any_defpath" = 0 ] && echo "(none — every definition names concepts and the two law-fixed addresses only)"
fi

echo
echo "### doc-lint [16] — RETIRED-REF: a live doc whose link resolves to a ⚰ RETIRED file"
# The link resolves, so [1] is green by design: the target exists and its own first line disowns
# it. Not sources: files under archive/ or release/, and the signposts themselves.
retired_set=$(mktemp)
while IFS= read -r rf; do
  head -1 "$rf" 2>/dev/null | grep -qE '⚰|RETIRED' && printf '%s\n' "$rf"
done < <(git ls-files '*.md') > "$retired_set"
if [ ! -s "$retired_set" ]; then
  echo "(no ⚰ RETIRED files in this repo — skipped)"
  rm -f "$retired_set"
else
  any_retref=0
  while IFS= read -r f; do
    case "$f" in */archive/*|archive/*|*/release/*|release/*) continue ;; esac
    grep -qxF "$f" "$retired_set" && continue
    d=$(dirname "$f")
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
      u=${url%%#*}; [ -z "$u" ] && continue
      tgt=$(realpath -m --relative-to=. "$d/$(decode "$u")" 2>/dev/null)
      { [ -n "$tgt" ] && grep -qxF "$tgt" "$retired_set"; } || continue
      echo "RETIRED-REF  $f  ->  $url  (the target's first line carries the retirement marker: a signpost, not a surface — repoint the reference, or mark the mention as history)"
      any_retref=1
    done < <(links_of "$f")
  done < <(md_link_sources)
  rm -f "$retired_set"
  [ "$any_retref" = 0 ] && echo "(none — no live doc leans on a retired file)"
fi

echo
echo "### doc-lint [17] — COLD-LIVE-TOKEN: a live lifecycle token buried in cold storage"
# The owed-counter reads the live inbox only. A FINDING is a live token in the token position of
# an ENTRY (`- <date> — <from> → <to>: **[OPEN` - bracket plus token, right after the entry's
# header colon; an entry whose token is unbracketed prose and only QUOTES `[OPEN]` is not one). A line
# that merely quotes the grammar is counted and reported on one line, never listed: on a real
# archive the quotes outnumber the entries, and a list nobody can triage hides the one that matters.
cold17=$(ls .critos/shared/archive/HANDOFFS-archive-*.md 2>/dev/null)
if [ -z "$cold17" ]; then
  echo "(no HANDOFFS archives in this repo — skipped)"
else
  any17=$(grep -nE '\[(OPEN\b|PARKED-OWNED\b)' $cold17 /dev/null 2>/dev/null || true)
  hits17=$(printf '%s\n' "$any17" | grep -E '^[^:]+:[0-9]+:[[:space:]]*- [0-9]{4}-[0-9]{2}-[0-9]{2}[^[]*:[[:space:]]*(\*\*)?\[(OPEN\b|PARKED-OWNED\b)' || true)
  quoted17=$(( $(printf '%s\n' "$any17" | grep -c . || true) - $(printf '%s\n' "$hits17" | grep -c . || true) ))
  if [ -n "$hits17" ]; then
    printf '%s\n' "$hits17" | sed 's/^/COLD-LIVE-TOKEN  /'
  else
    echo "(none — cold storage holds only settled tokens)"
  fi
  [ "$quoted17" -gt 0 ] && echo "($quoted17 other line(s) quote a live token in prose or inside a settled entry — not findings)"
fi

echo
echo "### doc-lint [18] — DEFINITION-SHAPE: an agent definition outside the template's section shape"
# Four mandatory sections, plus the optional '5 · Standing directives' (contract-agent § 1).
if [ -z "$def_files" ]; then
  echo "(no agent definitions in this repo — skipped)"
else
  any_shape18=0
  want18='^## (1 · Purpose|2 · Domain|3 · What I do NOT do|4 · Write surfaces I touch|5 · Standing directives)$'
  while IFS= read -r df; do
    [ -f "$df" ] || continue
    secs18=$(grep -E '^## ' "$df")
    extra18=$(printf '%s\n' "$secs18" | grep -vE "$want18" || true)
    missing18=""
    for s18 in "1 · Purpose" "2 · Domain" "3 · What I do NOT do" "4 · Write surfaces I touch"; do
      printf '%s\n' "$secs18" | grep -qxF "## $s18" || missing18="$missing18 · $s18"
    done
    if [ -n "$extra18" ] || [ -n "$missing18" ]; then
      echo "DEFINITION-SHAPE  $df — the template's section shape, exactly (contract-agent § 1):"
      [ -n "$extra18" ]   && printf '%s\n' "$extra18"   | sed 's/^/                  extra:   /'
      [ -n "$missing18" ] && echo "                  missing:${missing18}"
      any_shape18=1
    fi
  done <<< "$def_files"
  [ "$any_shape18" = 0 ] && echo "(none — every definition carries the template's shape: the four, plus at most the optional §5)"
fi

echo
echo "### doc-lint [19] — DEFINITION-ACTOR: a definition naming an actor other than itself"
# The one legal id is the definition's own (the filename's); a neighbour is named by its DOMAIN
# and the roster resolves it.
if [ -z "$def_files" ]; then
  echo "(no agent definitions in this repo — skipped)"
else
  any_actor19=0
  while IFS= read -r df; do
    [ -f "$df" ] || continue
    own19=$(basename "$df" | grep -oE '[0-9]+' | head -1)
    hits19=$(grep -noE '\bA[0-9]+\b' "$df" | grep -v ":A${own19}$" || true)
    if [ -n "$hits19" ]; then
      echo "DEFINITION-ACTOR  $df — names an actor other than itself (name the neighbour's DOMAIN; the roster resolves it):"
      printf '%s\n' "$hits19" | sed 's/^/                  line /'
      any_actor19=1
    fi
  done <<< "$def_files"
  [ "$any_actor19" = 0 ] && echo "(none — every definition names domains, and itself, only)"
fi

echo
echo "### doc-lint [20] — SHELF-INDEX: a rostered shelf whose index does not resolve, or whose folder holds unlisted documents"
# ADDRESS: every link in a Shelf cell resolves to a file (the index).
# LIST: where that index is the folder's README.md, every tracked .md under the folder (archives
#   excluded) is reachable from the INDEX CHAIN — the index and the READMEs it links,
#   transitively. A link from a non-index sibling does not count.
# Any other entry point is legal and its completeness is the owner's (a declared bound). A cell
# with no link and not "—" is a finding, unless it names another repo.
if [ -z "$ROSTER" ]; then
  echo "(no roster in this repo — skipped)"
else
  shelf_col=$(awk -F'|' '$2 ~ /^[[:space:]]*#[[:space:]]*$/ && tolower($0) ~ /shelf/ { for(i=1;i<=NF;i++) if (tolower($i) ~ /shelf/) {print i; exit} }' "$ROSTER" | head -1)
  if [ -z "$shelf_col" ]; then
    echo "(the roster has no Shelf column — skipped)"
  else
    any20=0
    rdir20=$(dirname "$ROSTER")
    while IFS= read -r row20; do
      actor20=$(printf '%s' "$row20" | awk -F'|' '{gsub(/[^A-Za-z0-9]/,"",$2); print $2}')
      case "$actor20" in A[0-9]|A[0-9][0-9]) ;; *) continue ;; esac
      cell20=$(printf '%s' "$row20" | awk -F'|' -v c="$shelf_col" 'NF>c {print $c}')
      links20=$(printf '%s' "$cell20" | grep -oE '\]\([^)]+\)' | sed -E 's/^\]\(//; s/\)$//')
      if [ -z "$links20" ]; then
        printf '%s' "$cell20" | grep -qE '^[[:space:]]*—?[[:space:]]*(\*\(.*\)\*)?[[:space:]]*$' && continue
        if printf '%s' "$cell20" | grep -qiE 'another repo|\.claude/repos'; then
          echo "(note) $actor20 — shelf in another repo: checked when the battery runs there, if that repo rosters it"
        else
          echo "SHELF-INDEX  $actor20 — shelf declared without a markdown link: a prose address cannot be verified (the tier-2 form is a LINK to the index)"
          any20=1
        fi
        continue
      fi
      while IFS= read -r lk20; do
        [ -z "$lk20" ] && continue
        case "$lk20" in http://*|https://*|mailto:*|\#*) continue ;; esac
        u20=${lk20%%#*}; [ -z "$u20" ] && continue
        u20=${u20//%20/ }
        tgt20=$(realpath -m --relative-to=. "$rdir20/$u20" 2>/dev/null)
        if [ -z "$tgt20" ] || [ ! -f "$tgt20" ]; then
          echo "SHELF-INDEX  $actor20 — shelf address does not resolve: $lk20 (the shelf has no index; the boot's awareness step would open a door onto nothing)"
          any20=1
          continue
        fi
        [ "$(basename "$tgt20")" = "README.md" ] || continue
        sdir20=$(dirname "$tgt20")
        on20=$(mktemp); li20=$(mktemp); seen20=$(mktemp)
        git ls-files "$sdir20/*.md" 2>/dev/null | grep -vE '(^|/)archive/' | grep -vxF "$tgt20" | sort -u > "$on20"
        # Breadth-first over the index chain: only README.md nodes propagate reach, and only
        # within the shelf; everything a chain node links inside the shelf is listed.
        printf '%s\n' "$tgt20" > "$seen20"
        queue20="$tgt20"
        while [ -n "$queue20" ]; do
          next20=""
          while IFS= read -r src20; do
            [ -z "$src20" ] || [ ! -f "$src20" ] && continue
            d20=$(dirname "$src20")
            while IFS= read -r l2; do
              [ -z "$l2" ] && continue
              case "$l2" in http://*|https://*|mailto:*) continue ;; esac
              l2=${l2%%#*}; [ -z "$l2" ] && continue
              l2=${l2//%20/ }
              t2=$(realpath -m --relative-to=. "$d20/$l2" 2>/dev/null); [ -n "$t2" ] || continue
              case "$t2" in "$sdir20"/*) ;; *) continue ;; esac
              printf '%s\n' "$t2" >> "$li20"
              [ "$(basename "$t2")" = "README.md" ] || continue
              grep -qxF "$t2" "$seen20" && continue
              printf '%s\n' "$t2" >> "$seen20"
              next20="${next20}${t2}"$'\n'
            done < <(links_of "$src20")
          done <<< "$queue20"
          queue20="$next20"
        done
        sort -u "$li20" -o "$li20"
        un20=$(comm -23 "$on20" "$li20")
        if [ -n "$un20" ]; then
          echo "SHELF-INDEX  $actor20 — on the shelf, not reachable from its index chain ($tgt20 + the READMEs it links):"
          printf '%s\n' "$un20" | sed 's/^/                 /'
          any20=1
        fi
        rm -f "$on20" "$li20" "$seen20"
      done <<< "$links20"
    done < <(grep -E '^\|' "$ROSTER")
    [ "$any20" = 0 ] && echo "(none — every rostered shelf resolves, and every README-indexed shelf is link-complete)"
  fi
fi

echo
echo "### doc-lint [21] — CITED-ID: a decision or lesson id cited somewhere and declared nowhere"
# Decisions are cited by id, never by path — so the ids must resolve, and this is what checks it.
# DECLARED: every id in a heading of a DECISIONS or LESSONS-LEARNED log, archives included, plus
#   every id written in a log's HEAD (before its first entry) — the alias table of a retired
#   sequence — here and in every registered repo. A head may retire a WHOLE sequence by writing
#   its ids with the placeholder NNN (`ADR-OLD-NNN -> ADR-A2-NNN`): every id of that prefix
#   then resolves.
# CITED: every id in a tracked file, except where an id is not a citation: the pinned tier and
#   the skills (they quote examples), templates, archives (records), and the generated atlas.
# Declared bound: only the standard shape is seen (`ADR-<scope>-NNN`, `L-<scope>-NNN`); a range
# written in prose is seen at its two ends. An id of an UNREGISTERED repo is flagged: silence it
# in `.claude/doc-lint-exempt`, or register the repo.
id_re='\b(ADR|L)-[A-Za-z0-9]+-[0-9]{3,}\b'
declared21=$(mktemp); prefixes21=$(mktemp)
{ printf '%s\n' "$root"; constellation "$root"; } | while IFS= read -r r21; do
  [ -d "$r21" ] || continue
  { git -C "$r21" ls-files '*DECISIONS*.md' '*LESSONS*.md'; git -C "$r21" ls-files --others --exclude-standard -- '*DECISIONS*.md' '*LESSONS*.md'; } 2>/dev/null | sort -u \
  | while IFS= read -r lg21; do
      [ -f "$r21/$lg21" ] || continue
      grep -hoE "^#{1,4}[[:space:]]*$id_re" "$r21/$lg21" | grep -oE "$id_re"
      awk '/^#{1,4}[[:space:]]*(ADR|L)-[A-Za-z0-9]+-[0-9]/{exit} {print}' "$r21/$lg21" | grep -oE "$id_re"
    done
done | sort -u > "$declared21"
# retired prefixes: `PREFIX-NNN` on the LEFT of an arrow in a log's head, here and in every
# registered repo. Only the left side retires: the right side of `ADR-OLD-NNN -> ADR-A2-NNN` is
# the LIVE sequence, and retiring it too would silence every typo in a live id.
{ printf '%s\n' "$root"; constellation "$root"; } | while IFS= read -r r21; do
  [ -d "$r21" ] || continue
  git -C "$r21" ls-files '*DECISIONS*.md' '*LESSONS*.md' 2>/dev/null | while IFS= read -r lg21; do
    [ -f "$r21/$lg21" ] || continue
    awk '/^#{1,4}[[:space:]]*(ADR|L)-[A-Za-z0-9]+-[0-9]/{exit} {print}' "$r21/$lg21" \
      | grep -oE '\b(ADR|L)-[A-Za-z0-9]+-NNN\b[`*[:space:]]*(->|→)' | sed -E 's/NNN.*$//'
  done
done | sort -u > "$prefixes21"
if [ ! -s "$declared21" ]; then
  echo "(no decision or lesson log declares an id in this repo — skipped)"
else
  cited21=$(git grep -I -hoE "$id_re" -- . ':(exclude).critos/system' ':(exclude)*archive*' \
      ':(exclude).claude/skills' ':(exclude).claude/agents/agent-1.md' ':(exclude)skills/crit-*' \
      ':(exclude)*.tmpl' ':(exclude)MEMORY-INDEX.md' 2>/dev/null | sort -u)
  any21=0
  while IFS= read -r id21; do
    [ -z "$id21" ] && continue
    grep -qxF "$id21" "$declared21" && continue
    if [ -s "$prefixes21" ] && grep -qxF "$(printf '%s' "$id21" | sed -E 's/[0-9]+$//')" "$prefixes21"; then continue; fi
    if [ -n "$exempt_re" ] && printf '%s\n' "$id21" | grep -qE "$exempt_re"; then continue; fi
    where21=$(git grep -I -lw -F "$id21" -- . ':(exclude).critos/system' ':(exclude)*archive*' ':(exclude)MEMORY-INDEX.md' 2>/dev/null | head -3 | tr '\n' ' ')
    echo "CITED-ID  $id21 — declared in no decision or lesson log (archives included). Cited in: $where21"
    any21=1
  done <<< "$cited21"
  [ "$any21" = 0 ] && echo "(none — every cited id resolves to a log entry)"
fi
rm -f "$declared21" "$prefixes21"

# ---- multi-repo: repeat the whole battery in every repo this one registers ----------------------
# `.claude/repos`: one path per line, relative to this repo's root ('#' comments). One level only:
# a registered repo's own registry is not followed. (The parser sits with the helpers, above;
# duplicated in status-check.sh.)
if [ -z "${DOC_LINT_NO_CONSTELLATION:-}" ]; then
  # Re-invoke by absolute path: the child runs after a cd.
  self_abs="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    echo
    echo "############################################################"
    echo "###  constellation repo: $(basename "$r")"
    echo "############################################################"
    if [ ! -d "$r" ]; then
      echo "(registered in .claude/repos but MISSING on disk: $r)"
      continue
    fi
    (cd "$r" && DOC_LINT_NO_CONSTELLATION=1 DOC_LINT_CHILD=1 bash "$self_abs")
  done < <(constellation "$root")
fi
