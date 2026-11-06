#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# doc-lint — the deterministic documentation-hygiene battery (the steward's mechanical pass).
#
# The battery. This header is part of the interface: update it WITH the checks.
#   [1] BROKEN            a relative markdown link that does not resolve to an existing file;
#       TRACKED-MISSING   a path git tracks that is absent from the disk (an uncommitted deletion),
#                         said once and read by no check: every file list is filtered by existence
#   [2] PATH-IN-CODE      a top-level `doc/….md` path hard-coded in code (reference by ID or
#                         concept, never by path)
#   [3] ORPHAN            a tracked .md that no other tracked .md links to ([1] and [3] are the
#                         two halves of the "no floating doc" rule); ORPHAN-BY-USE (WARN) a doc
#                         linked only from an index or a history surface — nothing sends a reader
#   [4] DANGLING-SKILL    a /skill-name referenced in the skill layer that is not installed
#   [5] INBOX hygiene     ping-pong topics, [OPEN] entries with no "Done when:", diffused
#                         ownership (inbox-audit.mjs)
#   [6] STALE-Rx          an open ROADMAP row untouched for >=10 days
#   [7] BAD-TOKEN         an inbox lifecycle token outside the closed vocabulary (token-audit.mjs)
#   [8] STATUS-CHRONICLE  (WARN) a STATUS.md over the line budget or stacking dated AS-OF sections;
#       NOTE-CHRONICLE    (WARN) a per-entity note stacking dated headings — a diary, not a photograph
#   [9] STALE-STATUS      a STATUS.md whose last commit is >=14 days old; STALE-STAMP a STATUS
#                         whose Last updated day (the stamp bold or plain) is older than the day
#                         of its last commit (UTC)
#  [10] DANGLING-WIKI-LINK (WARN) a [[slug]] that resolves nowhere the repo can reach — never
#                         against the auto-memory; AUTO-MEMORY-CITED (WARN) a tracked .md citing
#                         a note of this machine's auto-memory
#  [11] TIER-3-LESSON     an accepted_rule that does not name its "Enforcement: tier N";
#       BAD-BOUND         a Bound: outside the eight; ENFORCEMENT-FORM (WARN) the field outside
#                         its one written form, or written mid-line where no reader sees it
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
#  [22] ROOTS             the roster's Roots column vs the tracked tree: UNROOTED (a file under no
#                         domain's root and no ruled surface) · OVERLAP (one root, two actors) ·
#                         DANGLING (a root matching nothing); a roster without the column: SKIPPED
#  [23] INBOX-ACTOR       a live inbox entry whose sender is not a rostered agent (AGENT 0 included:
#                         upstream receives, it never writes), or whose recipient is neither
#                         rostered nor AGENT 0 — settled entries included
#  [24] FUTURE-DATE       a stamp later than today (UTC) in a STAMP POSITION of a memory log, a
#                         STATUS, a register or their archives (an entry head, a token, an id
#                         heading, Last updated, a verdict, an aging mark) — dates in prose are
#                         plans and are not read
#  [25] POINTER-FORM      a rotation pointer in a live log outside its one shape, or with a state
#                         outside the three (done · superseded by <id> · consolidated in <id>) —
#                         a list line or a heading carrying the word; prose is not read;
#       ARCHIVE-NAME      a file under a memory archive/ outside DECISIONS-archive-YYYY-MM.md and
#                         LESSONS-LEARNED-archive-YYYY-MM.md
#  [26] NO-CARRIER        a live entry with no Carries line for its own id; CARRIES-FORM a line
#                         under **Carries.** outside the two shapes or with a state outside the
#                         three; UNCARRIED an id headed in an archive with no live carrier;
#                         CARRIER-CONFLICT an id carried as in force and as settled at once (a
#                         pointer consolidated in a live entry is not settled); TWO-HOMES an id
#                         headed in two folders' archives, or pointed from a folder whose own
#                         archive does not head it — an id has one home; a declared family's
#                         heading outside its declared home (`· home: a<N>` in id-families),
#                         or a declared home that is no memory folder, likewise; HEADED-TWICE an
#                         id headed more than once inside its home (live logs and archives
#                         together; a heading in the stub's form, `— ROTATED YYYY-MM-DD to`, is a
#                         stub, not an entry); UNTIERED a
#                         binds: line with no tier on the line and none in its entry's field
#  [27] IN-FORCE-STALE    an agent's generated IN-FORCE.md missing or differing from a fresh
#                         generation; IN-FORCE-BUDGET (WARN) one past 300 lines
#  [28] TIER-2-UNDETECTED a tier-2 claim (a field whose head says tier 2) naming no detector that
#                         exists — neither a leg of the product by its stable name, matched whole
#                         (a word of a name is not the name), nor a file under .critos/checks/a<N>/ whose
#                         head says Enforces: <id>; DETECTOR-HEAD a file under .critos/checks/
#                         outside a<N>/, without the head, or running a machine path;
#                         DETECTOR-CROSS-IMPORT a detector reaching into another agent's folder
#
# Ids: the method's grammar (`ADR-<scope>-NNN`, `L-<scope>-NNN`) plus the families a project
# declares in `.critos/project/id-families` — grammar, never an exemption; a family may name
# its home on its line (`· home: a<N>`), read by [26].
#
# Severity at birth (contract-system § 6): a leg introduced by a release reports as a WARN in a
# project pinned at that release — its line says so — and as a finding from the next release.
# Born in 1.2.0: [25] [26] [28] and IN-FORCE-STALE. A leg WARN by a declared bound stays WARN.
#
# A project that spans several repos registers them in `.claude/repos`; the whole battery is then
# repeated in each (one level, read-only).
#
# Two rules every check follows: a check that could not run says SKIPPED, never "(none)" — a
# zero produced by a broken pipeline is not evidence; and every finding is a FLAG for its owner,
# never a gate. Interpretive audits (redundancy, real drift, taxonomy) are not in scope.
#
# Usage:  bash ~/.claude/skills/crit-doc-lint/doc-lint.sh [--own a<N>]
#           --own a<N> (or --me <N>): the runner's folder — read from the working tree, by every
#           check and by the generators this battery calls; every other memory folder is read as
#           COMMITTED, its logs, archives, STATUS and notes as HEAD holds them (contract-memory
#           § 6): a run sees the repository as its runner may commit it, and a finding in a
#           neighbour's folder is on committed state, that owner's debt at its own round.
#           Without a name every memory folder is read as committed — a verification's run,
#           nobody's. The shared surfaces — the inbox and its archives, the registers, the
#           documents, the code, the pinned tier, the detectors — stay the tree.
set -uo pipefail
own_args=(); own_names=()
while [ $# -gt 0 ]; do
  case "$1" in
    --own) own_args+=(--own "$2"); own_names+=("$2"); shift 2 ;;
    --me) own_args+=(--own "a$2"); own_names+=("a$2"); shift 2 ;;
    *) shift ;;
  esac
done
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "doc-lint: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1
# An --own names a memory folder that exists — in the tree, or at HEAD: one line and exit 2 otherwise,
# never a battery that runs on as nobody's (contract-session § 6, the INSTRUMENT bound).
for o in ${own_names[@]+"${own_names[@]}"}; do
  case "$o" in a[0-9]|a[0-9][0-9]|a[0-9][0-9][0-9]) ;; *) echo "doc-lint: --own $o is not an owner's name (a<N>)" >&2; exit 2 ;; esac
  [ -d ".critos/memory/$o" ] || [ -n "$(git ls-tree -d --name-only HEAD -- ".critos/memory/$o" 2>/dev/null | head -1)" ] \
    || { echo "doc-lint: --own $o names no memory folder — .critos/memory/$o/ is neither in the tree nor at HEAD" >&2; exit 2; }
done

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
# ---- the memory folders, and where each is read ---------------------------------------------
# A control reads a memory folder its runner does not own as committed (contract-memory § 6). The
# folders the runner names (--own a<N>) are read from the working tree; every other memory folder
# is read as HEAD holds it — by every check, as by the generators the battery calls — and without
# a name every memory folder is read as committed. The unowned folders are materialized once, one
# git process per folder; a check reads the copy and reports the repository path. A repository
# with no commit yet has nothing that could be another's: its tree is read.
owned=()
for o in ${own_names[@]+"${own_names[@]}"}; do owned+=(".critos/memory/$o"); done
head_ok=1; git rev-parse -q --verify HEAD >/dev/null 2>&1 || head_ok=0
head_root=$(mktemp -d); head_list=$(mktemp); trap 'rm -rf "$head_root" "$head_list"' EXIT
[ "$head_ok" = 1 ] && git ls-tree -r --name-only HEAD -- '.critos/memory/' 2>/dev/null > "$head_list"
mem_owned() {   # $1 = a path: read from the tree? — outside the memory folders always; inside, when owned
  local t="$1" x
  [ "$head_ok" = 0 ] && return 0
  case "$t" in .critos/memory/*) ;; *) return 0 ;; esac
  t=${t#.critos/memory/}; t=".critos/memory/${t%%/*}"
  for x in ${owned[@]+"${owned[@]}"}; do [ "$x" = "$t" ] && return 0; done
  return 1
}
rd() { RD="$1"; mem_owned "$1" || RD="$head_root/$1"; }   # RD = where $1 is read: itself, or its HEAD copy
materialize() {   # $1 = a memory folder: its HEAD copy under $head_root, once — one git process per folder;
                  # the blobs' bytes, conversion off, as `git show` prints them
  [ -d "$head_root/$1" ] && return 0
  mkdir -p "$head_root/$1"
  git -c core.autocrlf=false -c core.eol=lf archive --format=tar HEAD -- "$1" 2>/dev/null | tar -xf - -C "$head_root" 2>/dev/null
  return 0
}
mem_dirs() {   # every memory folder, one per line: the owned ones from the tree, every other as committed
  { for o in ${owned[@]+"${owned[@]}"}; do [ -d "$o" ] && printf '%s\n' "$o"; done
    if [ "$head_ok" = 1 ]; then
      sed -nE 's#^(\.critos/memory/[^/]+)/.*$#\1#p' "$head_list" | sort -u | while IFS= read -r d; do mem_owned "$d" || printf '%s\n' "$d"; done
    else for d in .critos/memory/*/; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done; fi; } | sort -u
}
mem_ls() {   # $1 = a pathspec under .critos/memory/ -> the paths it matches: an owned folder's as git ls-files
             # lists them (the index), every other folder's as committed
  { git ls-files "$1" 2>/dev/null | while IFS= read -r f; do mem_owned "$f" && printf '%s\n' "$f"; done
    [ "$head_ok" = 1 ] && while IFS= read -r f; do [[ "$f" == $1 ]] && ! mem_owned "$f" && printf '%s\n' "$f"; done < "$head_list"; } | sort -u
}
mem_files() { mem_ls ".critos/memory/*/$1"; }
if [ "$head_ok" = 1 ]; then while IFS= read -r d; do [ -n "$d" ] && ! mem_owned "$d" && materialize "$d"; done < <(mem_dirs); fi
# A git grep over the repository as a run sees it: the tree outside the memory folders and inside the
# owned ones, HEAD inside every other memory folder (a HEAD hit's `HEAD:` prefix is stripped). The
# first argument is the positive pathspec (`.` or a glob such as `*.md`), then git grep's own
# arguments, then `--` and the exclude pathspecs.
mgrep() {
  local pos="$1" a=() ex=() hex=() o opos; shift
  while [ $# -gt 0 ]; do [ "$1" = "--" ] && { shift; ex=("$@"); break; }; a+=("$1"); shift; done
  if [ "$head_ok" = 0 ]; then git grep "${a[@]}" -- "$pos" ${ex[@]+"${ex[@]}"} 2>/dev/null; return 0; fi
  git grep "${a[@]}" -- "$pos" ':(exclude).critos/memory' ${ex[@]+"${ex[@]}"} 2>/dev/null
  for o in ${owned[@]+"${owned[@]}"}; do
    opos="$o"; [ "$pos" != . ] && opos="$o/$pos"
    [ -d "$o" ] && git grep "${a[@]}" -- "$opos" ${ex[@]+"${ex[@]}"} 2>/dev/null
    hex+=(":(exclude)$o")
  done
  opos=".critos/memory"; [ "$pos" != . ] && opos=".critos/memory/$pos"
  git grep "${a[@]}" HEAD -- "$opos" ${hex[@]+"${hex[@]}"} ${ex[@]+"${ex[@]}"} 2>/dev/null | sed 's/^HEAD://'
  return 0
}

_ver=""
if [ -d .critos ]; then
  _ver=$(grep -hoE '"system"[^,]*' .critos/system/VERSION 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?' | head -1)
  echo "### layout: .critos/ — system ${_ver:-?}"
elif [ -f system/VERSION ] && [ -f releases.manifest ]; then
  echo "### layout: this repo is CritOS itself (it publishes its system tier, it does not install it)"
else
  echo "### layout: NONE — no CritOS layer found in this repo (only the repo-wide checks can run)"
fi
[ -n "$inbox_retired" ] && echo "### (a ⚰ RETIRED inbox exists: $inbox_retired — a signpost, not a channel; it counts toward nothing)"
# Severity at birth (contract-system § 6): a leg a release introduces reports as a WARN in a
# project pinned at that release and as a finding from the next — the leg carries its version,
# the battery compares it with the pin's base. `born <version>` appends the annotation while the
# pin is at that release; a leg WARN by a declared bound never calls it.
pin_base=${_ver%%-rc*}
born() { [ -n "$pin_base" ] && [ "$pin_base" = "$1" ] && printf ' (WARN — new in %s: a finding from the next release)' "$1"; return 0; }
# Every check's block ends with its elapsed seconds, and the run ends with the total: a slow run
# names the check that costs, not the run. `hdr` prints the previous block's figure, a blank
# line, then the header of the next check.
t_start=$(date +%s); t_prev=$t_start; t_n=""
hdr() { local now; now=$(date +%s); [ -n "$t_n" ] && echo "(elapsed [$t_n]: $((now - t_prev))s)"; t_prev=$now; t_n=$1; echo; echo "### doc-lint [$1] — $2"; }

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
# The tracked .md ON THE DISK: a tracked path absent from it (an uncommitted deletion) is said
# once by [1] and read by nothing — a dead awk prints a none it has not earned.
# The memory files among them where the run reads them (an unowned folder as committed), the
# repository path printed: a reader calls `rd` for the path to open.
tracked_md() { { git ls-files '*.md' | grep -v '^\.critos/memory/'; mem_ls '.critos/memory/*.md'; } | while IFS= read -r f; do rd "$f"; [ -f "$RD" ] && printf '%s\n' "$f"; done; }
md_link_sources() { { tracked_md; git ls-files --others --exclude-standard -- '*.md' | while IFS= read -r f; do mem_owned "$f" && printf '%s\n' "$f"; done; } | sort -u; }
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

# ---- the id grammar -----------------------------------------------------------------------------
# A decision or lesson id is `ADR-<scope>-NNN` or `L-<scope>-NNN` (contract-memory § 2, § 3). A
# project whose history carries ids under earlier schemes declares them in
# `.critos/project/id-families` — one extended regex per line, '#' comments — and every reader of
# an id in this battery (the citations, the pointers, the carriers) reads those families as ids
# too. A declared family is grammar, never an exemption: its ids must resolve like any other.
# A line may name the family's HOME after its regex (`^D-[0-9]{3}$ · home: a2`): every reader
# strips the suffix before it reads the regex; [26] reads the declaration.
id_core='(ADR|L)-[A-Za-z0-9]+-[0-9]{3,}'
if [ -f .critos/project/id-families ]; then
  fam=$(grep -vE '^[[:space:]]*(#|$)' .critos/project/id-families | sed -E 's/[[:space:]]*·[[:space:]]*home:.*$//; s/^\^//; s/\$$//' | paste -sd'|' -)
  [ -n "$fam" ] && id_core="$id_core|$fam"
fi
id_re="\\b($id_core)\\b"
# A rotation pointer's stub form — `— ROTATED YYYY-MM-DD to` — is what every reader of an archive or
# of a log's headings skips: a heading in this form is a stub of the old pointer shape, never an
# entry; a heading whose title merely names the word is the entry it says it is.
rot_re='— ROTATED 20[0-9]{2}-[0-9]{2}-[0-9]{2} to '

hdr 1 "broken relative links in .md (existence-checked per link; tracked + untracked)"
# First, the index vs the tree: a path git tracks that is absent from the disk — an uncommitted
# deletion, yours or a neighbour's. Said once, here; every check reads the tree without it.
while IFS= read -r -d '' f; do
  mem_owned "$f" || continue   # a neighbour's memory folder is read as committed: nothing is missing there
  [ -e "$f" ] || echo "TRACKED-MISSING  $f  (tracked by git, absent on disk — an uncommitted deletion, yours or a neighbour's: commit it or restore it; every check reads the tree without it)"
done < <(git ls-files -z 2>/dev/null)
any_broken=0
while IFS= read -r f; do
  d=$(dirname "$f"); rd "$f"
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
    u=${url%%#*}; [ -z "$u" ] && continue
    u=$(decode "$u")
    if [ ! -e "$d/$u" ]; then
      echo "BROKEN  $f  ->  $url"
      any_broken=1
    fi
  done < <(links_of "$RD")
done < <(md_link_sources)
[ "$any_broken" = 0 ] && echo "(none — all relative links resolve)"

hdr 2 "top-level doc/*.md paths hard-coded in code (fragile breadcrumbs)"
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

hdr 3 "ORPHAN docs: tracked .md that nothing links to (the 'no floating doc' rule)"
# The reachability graph is built from TRACKED sources only: an uncommitted pointer can vanish.
targets=$(mktemp)
while IFS= read -r f; do
  d=$(dirname "$f"); rd "$f"
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
    u=${url%%#*}; [ -z "$u" ] && continue
    realpath -m --relative-to=. "$d/$(decode "$u")" 2>/dev/null
  done < <(links_of "$RD")
done < <(tracked_md) | sort -u > "$targets"
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
    STATUS.md|DECISIONS.md|LESSONS-LEARNED.md|IN-FORCE.md|IN-FORCE.*.md) continue ;;
    HANDOFFS.md|ROADMAP.md|CONTRACTS.md|VERSION|CHANGELOG.md) continue ;;
  esac
  case "$f" in .critos/memory/*/notes/*) continue ;; esac
  if [ -n "$exempt_re" ] && printf '%s\n' "$f" | grep -qE "$exempt_re"; then continue; fi
  grep -qxF "$f" "$targets" || { echo "ORPHAN  $f  (no tracked .md points at it — register it in its index, or archive it)"; any_orphan=1; }
done < <(tracked_md)
[ "$any_orphan" = 0 ] && echo "(none — every doc is reachable from an index)"
# The second leg, ORPHAN-BY-USE (WARN): linked is not read. A document earns its place when a
# surface that DISPATCHES a reader names it — a SKILL.md, an agent definition, the roster, the
# contracts register, a live non-index document. An index (README.md, CLAUDE.md) lists; it does
# not send. History surfaces never count as namers: archive/ folders, the memory logs and their
# archives, the inbox and the roadmap, the generated indexes. One hop, declared: a namer is not
# itself checked for being read. The pinned tier and the project tier are read by the boot and
# are not candidates; the same exemptions as ORPHAN apply.
dispatch=$(mktemp)
while IFS= read -r f; do
  case "$f" in
    */archive/*|archive/*|*-archive-*) continue ;;
    .critos/memory/*/STATUS.md|.critos/memory/*/DECISIONS.md|.critos/memory/*/LESSONS-LEARNED.md|.critos/memory/*/IN-FORCE*.md) continue ;;
    .critos/shared/HANDOFFS.md|.critos/shared/ROADMAP.md|MEMORY-INDEX.md|*/MEMORY-INDEX.md) continue ;;
    .critos/system/*|*.tmpl) continue ;;
  esac
  case "$(basename "$f")" in README.md|CLAUDE.md|CLAUDE.global.md|AGENTS.md|MEMORY.md) continue ;; esac
  d=$(dirname "$f"); rd "$f"
  while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
    u=${url%%#*}; [ -z "$u" ] && continue
    realpath -m --relative-to=. "$d/$(decode "$u")" 2>/dev/null
  done < <(links_of "$RD")
done < <(tracked_md) | sort -u > "$dispatch"
any_byuse=0
while IFS= read -r f; do
  case "$(basename "$f")" in
    README.md|CLAUDE.md|CLAUDE.global.md|AGENTS.md|SKILL.md|MEMORY.md|MEMORY-INDEX.md) continue ;;
    STATUS.md|DECISIONS.md|LESSONS-LEARNED.md|IN-FORCE.md|IN-FORCE.*.md) continue ;;
    HANDOFFS.md|ROADMAP.md|CONTRACTS.md|VERSION|CHANGELOG.md) continue ;;
  esac
  case "$f" in .critos/memory/*/notes/*|.critos/system/*|.critos/project/*|*/archive/*|archive/*|*-archive-*) continue ;; esac
  if [ -n "$exempt_re" ] && printf '%s\n' "$f" | grep -qE "$exempt_re"; then continue; fi
  grep -qxF "$f" "$targets" || continue          # an ORPHAN already, above
  grep -qxF "$f" "$dispatch" && continue
  echo "ORPHAN-BY-USE  $f  (linked only from an index or a history surface — no skill, definition, roster, contracts row or live document sends a reader here: a procedure an agent runs is a skill; a guide earns its place by a reader sent to it, or it is archived)"
  any_byuse=1
done < <(tracked_md)
rm -f "$targets" "$dispatch"
[ "$any_byuse" = 0 ] && echo "(no document linked only from an index: every reachable doc has a reader sent to it)"

hdr 4 "DANGLING skill references in the agentic docs"
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
scan=$(tracked_md | grep -E '(SKILL\.md$|^CLAUDE\.md$)' | grep -v '/crit-doc-lint/' || true)
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

hdr 5 "INBOX hygiene (ping-pong · no closure criterion · diffused ownership)"
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

hdr 6 "STALE-Rx: open ROADMAP rows nobody has touched in >=10 days"
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

hdr 7 "BAD-TOKEN: inbox entries whose lifecycle token is outside the closed vocabulary"
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

hdr 8 "STATUS-CHRONICLE (WARN): a memory STATUS.md that stopped being a snapshot"
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
  rd "$sf"; n=$(grep -c '' "$RD")
  asof_re='AS[ -]OF|SESSION (CLOSE|END)|CURRENT STATE'
  [ -f .claude/doc-lint-status-headings ] && \
    asof_re="$asof_re|$(grep -vE '^[[:space:]]*(#|$)' .claude/doc-lint-status-headings | paste -sd'|' -)"
  asof=$(grep -cE "^#{1,4}[[:space:]].*($asof_re)[^A-Za-z]*[0-9]{4}-[0-9]{2}-[0-9]{2}" "$RD")
  if [ "$n" -gt "$status_max" ] || [ "$asof" -gt 1 ]; then
    echo "STATUS-CHRONICLE  $sf — ${n} lines (budget ${status_max}), ${asof} dated AS-OF sections."
    echo "                  A STATUS is OVERWRITTEN, not prepended: keep what is TRUE NOW, let git hold the history."
    any_chronicle=1
  fi
done <<< "$status_files"
[ -n "$status_files" ] && [ "$any_chronicle" = 0 ] && echo "(none — every STATUS reads as a snapshot)"
# The second leg, NOTE-CHRONICLE (WARN): a per-entity note is the photograph of one entity, not
# its diary (contract-memory § 4). The same fingerprint, read on every file under
# `.critos/memory/a<N>/notes/`, folders included — dated headings stacking (more than one) — with
# no line budget, because a note may grow; each folder's README.md is the kind's contract and
# is not read. A date in prose qualifies evidence and is not a heading.
any_note=0
while IFS= read -r nf; do
  [ -n "$nf" ] || continue; rd "$nf"; [ -f "$RD" ] || continue
  [ "$(basename "$nf")" = README.md ] && continue
  dated=$( { grep -cE '^#{1,4}[[:space:]].*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$RD" || true; } 2>/dev/null)
  if [ "${dated:-0}" -gt 1 ]; then
    echo "NOTE-CHRONICLE  $nf — ${dated} dated headings. A note is OVERWRITTEN when its entity is touched: present tense, one photograph; a date only where it qualifies evidence (contract-memory § 4)."
    any_note=1
  fi
done < <(mem_ls '.critos/memory/a*/notes/*' | grep -E '\.md$')
[ "$any_note" = 0 ] && echo "(no per-entity note reads as a diary)"

hdr 9 "STALE-STATUS: a memory STATUS.md nobody has touched in >=14 days · STALE-STAMP: a head stamp older than the file's last commit"
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
    rd "$sf"
    age=$(( (now9 - ct) / 86400 ))
    if [ "$age" -ge 14 ]; then
      echo "STALE-STATUS  $sf — last commit ${age}d ago. Re-verify with its owner: is this still true?"
      any_stale_status=1
    fi
    # STALE-STAMP: the head stamp is a claim a control reads. The `Last updated:` day against the
    # day of the file's last commit, both UTC: older is a finding — the head the boot trusts says
    # an older day than the file; newer is the writer mid-round (the tree ahead of its commit),
    # not a finding; a day later than today is [24]'s. No stamp line: nothing to read here. The
    # stamp is read bold (the template's form) or plain (the contract's), at the line's start.
    cday=$(date -u -d "@$ct" +%F 2>/dev/null || date -u -r "$ct" +%F 2>/dev/null)
    sday=$(grep -m1 -oE '^[*_]{0,2}Last updated:[*_]{0,2}[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$RD" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}$')
    if [ -n "$cday" ] && [ -n "$sday" ] && [[ "$sday" < "$cday" ]]; then
      echo "STALE-STAMP  $sf — stamped $sday, last committed $cday (UTC): the head the boot trusts is older than the file; re-stamp with date -u when the file changes$(born 1.2.0)"
      any_stale_status=1
    fi
  done <<< "$status_files"
  [ "$any_stale_status" = 0 ] && echo "(none — every STATUS was touched in the last 14 days, and no head stamp is older than its commit)"
fi

hdr 10 "DANGLING-WIKI-LINK (WARN): a [[slug]] that resolves nowhere reachable"
# A slug resolves if it is (a) a heading or ID declared in a tracked .md, (a2) a tracked doc's
# basename, (a3) a token-shaped first cell of a table row, or (b) exempted in
# `.claude/doc-lint-exempt`. Never against the assistant's auto-memory: a link that resolved
# only there read green on the one machine that has it (contract-system § 3, the auto-memory
# row). Archives are records and are not scanned; this skill's own docs quote the syntax.
wl_tmp=$(mktemp); wl_declared=$(mktemp)
mgrep '*.md' -hoE '\[\[[A-Za-z0-9][A-Za-z0-9._-]*\]\]' -- ':(exclude)*archive*' ':(exclude)*skills/crit-doc-lint/*' \
  | sed -E 's/^\[\[//; s/\]\]$//' | sort -u > "$wl_tmp"
if [ ! -s "$wl_tmp" ]; then
  echo "(no [[slug]] links in this repo — skipped)"
  rm -f "$wl_tmp" "$wl_declared"
else
{
  mgrep '*.md' -hoE '^#{1,6}[[:space:]]+[A-Za-z0-9][A-Za-z0-9._-]*' -- \
    | sed -E 's/^#+[[:space:]]+//'
  { git ls-files '*.md' 2>/dev/null | grep -v '^\.critos/memory/'; mem_ls '.critos/memory/*.md'; } | while IFS= read -r p; do b=${p##*/}; printf '%s\n' "${b%.md}"; done
  mgrep '*.md' -hoE '^\|[[:space:]]*~{0,2}[A-Za-z][A-Za-z0-9._-]{0,23}~{0,2}[[:space:]]*\|' -- \
    | sed -E 's/^\|[[:space:]]*//; s/[[:space:]]*\|$//; s/~~//g'
} | sort -u > "$wl_declared"
any_wl=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  grep -qxF "$s" "$wl_declared" && continue
  if [ -n "$exempt_re" ] && printf '%s\n' "$s" | grep -qE "$exempt_re"; then continue; fi
  where=$(mgrep '*.md' -l -F "[[$s]]" -- | head -3 | tr '\n' ' ')
  echo "DANGLING-WIKI-LINK  [[$s]] — declared nowhere reachable. Cited in: $where"
  any_wl=1
done < "$wl_tmp"
rm -f "$wl_tmp" "$wl_declared"
[ "$any_wl" = 0 ] && echo "(none — every [[slug]] resolves)"
fi
# The second leg, AUTO-MEMORY-CITED (WARN): a tracked .md naming, in backticks or a wiki-link,
# a note of the assistant's auto-memory on this machine — every project folder under
# `~/.claude/projects/*/memory/` (one project moves and leaves several). A fact a tracked
# artifact needs lives in the repo (contract-system § 3): the owner moves it in and repoints.
# Declared bound: a true positive only where the note exists, silent elsewhere; archives are
# records and are not read, and code files are not read. CRITOS_AUTO_MEMORY names another root
# (the test suite plants one, so the leg is seen firing on every machine).
am_root="${CRITOS_AUTO_MEMORY:-$HOME/.claude/projects}"
am_names=$(ls -1 "$am_root"/*/memory/*.md 2>/dev/null | xargs -n1 basename 2>/dev/null | sed 's/\.md$//' | grep -vxE 'MEMORY|README' | sort -u)
if [ -z "$am_names" ]; then
  echo "(no auto-memory note on this machine under $am_root — the citation leg cannot fire here; not a clean none elsewhere)"
else
  am_re=$(printf '%s\n' "$am_names" | sed -E 's/[.[\*^$|]/\\&/g' | paste -sd'|' -)
  any_am=0
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo "AUTO-MEMORY-CITED  $hit — a note of the assistant's auto-memory, cited from a tracked file: the fact it holds lives in the repo, or the citation lies on every other machine (contract-system § 3)"
    any_am=1
  done < <(mgrep '*.md' -noE "(\`|\[\[)($am_re)(\`|\]\])" -- ':(exclude)*archive*' ':(exclude)*skills/crit-doc-lint/*' ':(exclude).critos/system' ':(exclude)*.tmpl' | head -40)
  [ "$any_am" = 0 ] && echo "(no tracked file cites an auto-memory note of this machine)"
fi

hdr 11 "TIER-3 LESSON: an accepted_rule that does not name its enforcement tier"
# A lessons log is written as headings (`## L-A<N>-NNN …`) or as top-level bullets
# (`- **YYYY-MM-DD · accepted_rule — …`): the shape is detected first, because a bullet boundary
# inside a heading-shaped file would split entries at their own lists. The field is read at its
# syntactic position — a line that STARTS with it — never anywhere in the body.
tier3_out=$(
  mem_files LESSONS-LEARNED.md | while IFS= read -r lf; do
      rd "$lf"; [ -f "$RD" ] || continue
      shape=headings
      [ "$( { grep -cE '^#{1,4}[[:space:]]+.*(L-[A-Za-z0-9]+-[0-9]|[0-9]{4}-[0-9]{2}-[0-9]{2})' "$RD" || true; } 2>/dev/null)" = 0 ] && shape=bullets
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
        hdr != "" {
          if ($0 ~ /accepted_rule/) acc = 1
          if ($0 ~ /^[[:space:]]*(-[[:space:]]+)?[*_]{0,2}[Ee]nforcement:/) has = 1
          # the optional Bound: field (contract-memory § 3) — read at its position, its value one of the eight
          if ($0 ~ /^[[:space:]]*(-[[:space:]]+)?[*_]{0,2}[Bb]ound:/) {
            v = $0; sub(/^[^:]*:[*_]*[[:space:]]*/, "", v); sub(/[^A-Za-z].*$/, "", v)
            if (v !~ /^(TIME|LAYER|SHAPE|TARGET|INSTRUMENT|ACTION|ABSENCE|BASELINE)$/)
              printf "BAD-BOUND  %s:%d  Bound: %s — not one of the eight bounds of contract-session § 6 (TIME LAYER SHAPE TARGET INSTRUMENT ACTION ABSENCE BASELINE)\n", f, NR, (v == "" ? "(empty)" : v)
          }
        }
        END {
          flush()
          if (undated > 0) printf "UNDATED-LESSON %s — %d accepted_rule entr%s skipped (no date)\n", f, undated, (undated == 1 ? "y" : "ies")
        }
      ' "$RD"
    done
)
if [ -n "$tier3_out" ]; then
  printf '%s\n' "$tier3_out"
  if printf '%s\n' "$tier3_out" | grep -q '^TIER-3-LESSON'; then
    echo "               → each: add \"**Enforcement:** tier N — <detector>\" (1 impossible · 2 detected deterministically · 3 written-and-hoped),"
    echo "                 and for tier 3 say why no detector is possible."
  fi
else
  echo "(none — every accepted_rule names its enforcement tier, and every Bound: names one of the eight)"
fi
# The third leg, ENFORCEMENT-FORM (WARN): the field in ONE written form — the bold label, a
# space, `tier N` with a space and the digit, then nothing or an em dash and the detector
# (contract-memory § 3). Read in both logs at the line's start, fenced blocks skipped (a log's
# head shows the shape inside a fence); a variant is reported, never gated. A field written
# mid-line, after other text, is reported too: every reader reads the line's start, so nothing
# sees it — inline code spans are stripped first, so a line that quotes the label is not read.
form11=$( { mem_files DECISIONS.md; mem_files LESSONS-LEARNED.md; } | while IFS= read -r lf; do
  rd "$lf"; [ -f "$RD" ] || continue
  num11=$(mktemp)
  awk '/^[[:space:]]*```/{f=!f;next} !f{print NR ":" $0}' "$RD" > "$num11"
  grep -E '^[0-9]+:(-[[:space:]]+)?[*_]{0,2}[Ee]nforcement[*_]{0,2}:' "$num11" \
    | grep -vE '^[0-9]+:\*\*Enforcement:\*\* tier [123]( — .*)?$' \
    | sed -E "s|^([0-9]+):(.{0,70}).*|ENFORCEMENT-FORM  $lf:\1  \2|"
  sed -E 's/`[^`]*`//g' "$num11" \
    | grep -E '^[0-9]+:.+\*\*Enforcement:\*\*' \
    | grep -vE '^[0-9]+:(-[[:space:]]+)?[*_]{0,2}[Ee]nforcement[*_]{0,2}:' \
    | sed -E "s|^([0-9]+):(.{0,70}).*|ENFORCEMENT-FORM  $lf:\1  \2 — written mid-line: no reader sees it|"
  rm -f "$num11"
done)
if [ -n "$form11" ]; then
  printf '%s\n' "$form11"
  echo "               → one written form, at the line's start: **Enforcement:** tier N — <the detector, or why none is possible>; a split tier is two Carries lines"
else
  echo "(no Enforcement: line outside the one written form)"
fi

hdr 12 "UNROTATED LOG: an append-only memory log past the skimmable budget"
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
  rd "$lg"; [ -f "$RD" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  n=$(grep -c '' "$RD")
  [ "$n" -gt "$log_max" ] || continue
  ents=$( { grep -cE '^#{1,4}[[:space:]]*(ADR|D|L)-' "$RD" || true; } 2>/dev/null)
  if head -n 60 "$RD" | grep -qE 'DECLARED EXEMPTION[^A-Za-z]{0,8}ACTIVE'; then
    why=$(head -n 60 "$RD" | grep -E 'DECLARED EXEMPTION[^A-Za-z]{0,8}ACTIVE' | head -1 | sed -E 's/^[>[:space:]*#]*//; s/\*\*//g' | cut -c1-150)
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
  rd "$lg"; [ -f "$RD" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  arch=$( { grep -cE '^\*\*Status[^*]*\*\*:?.*(superseded by|completed [0-9]{4})' "$RD" || true; } 2>/dev/null)
  [ "${arch:-0}" -gt 0 ] && echo "ARCHIVABLE     $lg — ${arch} entr$( [ "$arch" = 1 ] && echo y || echo ies) marked fully superseded/completed still in the live log (aging trigger 1, contract-memory §2 — the owner archives, or A1 will)"
done < <(logs12)
[ "$any_unrotated" = 0 ] && echo "(none — every append-only memory log is within budget, or declares its overage in its own head)"

hdr 13 "MEMORY-SHAPE: one agent, one folder, one writer, one address"
if [ -d .critos/memory ]; then
  any_shape=0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    b=${d##*/}
    case "$b" in
      a[0-9]|a[0-9][0-9]) ;;
      *) echo "MEMORY-SHAPE  .critos/memory/$b — not an agent folder. The address IS the owner (a<N>); a folder named otherwise cannot be attributed by structure and falls back to a roster grep that can drift."; any_shape=1; continue ;;
    esac
    [ -n "$ROSTER" ] || continue
    n=${b#a}
    grep -qE "^\|[[:space:]]*(A)?${n}[[:space:]]*\|" "$ROSTER" \
      || { echo "MEMORY-SHAPE  .critos/memory/$b exists but no row for A${n} in $ROSTER — an unrostered writer is an owner nobody can route to."; any_shape=1; }
  done < <(mem_dirs)
  [ "$any_shape" = 0 ] && echo "(none — every memory folder is a<N> and every one of them is rostered)"
else
  echo "(no .critos/memory/ in this repo — skipped)"
fi

hdr 14 "PIN-DRIFT: the pinned system tier vs its declared release"
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

hdr 15 "DEFINITION-PATH: a path in an agent definition, beyond the law-fixed addresses"
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

hdr 16 "RETIRED-REF: a live doc whose link resolves to a ⚰ RETIRED file"
# The link resolves, so [1] is green by design: the target exists and its own first line disowns
# it. Not sources: files under archive/ or release/, and the signposts themselves.
retired_set=$(mktemp)
while IFS= read -r rf; do
  rd "$rf"; head -1 "$RD" 2>/dev/null | grep -qE '⚰|RETIRED' && printf '%s\n' "$rf"
done < <(tracked_md) > "$retired_set"
if [ ! -s "$retired_set" ]; then
  echo "(no ⚰ RETIRED files in this repo — skipped)"
  rm -f "$retired_set"
else
  any_retref=0
  while IFS= read -r f; do
    case "$f" in */archive/*|archive/*|*/release/*|release/*) continue ;; esac
    grep -qxF "$f" "$retired_set" && continue
    d=$(dirname "$f"); rd "$f"
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      case "$url" in http://*|https://*|mailto:*|\#*) continue ;; esac
      u=${url%%#*}; [ -z "$u" ] && continue
      tgt=$(realpath -m --relative-to=. "$d/$(decode "$u")" 2>/dev/null)
      { [ -n "$tgt" ] && grep -qxF "$tgt" "$retired_set"; } || continue
      echo "RETIRED-REF  $f  ->  $url  (the target's first line carries the retirement marker: a signpost, not a surface — repoint the reference, or mark the mention as history)"
      any_retref=1
    done < <(links_of "$RD")
  done < <(md_link_sources)
  rm -f "$retired_set"
  [ "$any_retref" = 0 ] && echo "(none — no live doc leans on a retired file)"
fi

hdr 17 "COLD-LIVE-TOKEN: a live lifecycle token buried in cold storage"
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

hdr 18 "DEFINITION-SHAPE: an agent definition outside the template's section shape"
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

hdr 19 "DEFINITION-ACTOR: a definition naming an actor other than itself"
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

hdr 20 "SHELF-INDEX: a rostered shelf whose index does not resolve, or whose folder holds unlisted documents"
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

hdr 21 "CITED-ID: a decision or lesson id cited somewhere and declared nowhere"
# Decisions are cited by id, never by path — so the ids must resolve, and this is what checks it.
# DECLARED: every id in a heading of a DECISIONS or LESSONS-LEARNED log, archives included, plus
#   every id written in a log's HEAD (before its first entry) — the alias table of a retired
#   sequence — here and in every registered repo. A head may retire a WHOLE sequence by writing
#   its ids with the placeholder NNN (`ADR-OLD-NNN -> ADR-A2-NNN`): every id of that prefix
#   then resolves.
# CITED: every id in a tracked file, except where an id is not a citation: the pinned tier and
#   the skills (they quote examples), templates, archives (records), and the generated atlas.
# Declared bound: only the standard shape is seen (`ADR-<scope>-NNN`, `L-<scope>-NNN`), plus the
# families the project declares in `.critos/project/id-families`; a range written in prose is
# seen at its two ends. An id of an UNREGISTERED repo is flagged: silence it in
# `.claude/doc-lint-exempt`, or register the repo.
declared21=$(mktemp); prefixes21=$(mktemp)
# the logs of this repo where the run reads them (a memory folder not owned as committed; an owned
# one tracked and new); a registered repo's as its tree, one level, read-only
logs21_home() {
  { { git ls-files '*DECISIONS*.md' '*LESSONS*.md'; git ls-files --others --exclude-standard -- '*DECISIONS*.md' '*LESSONS*.md'; } 2>/dev/null | grep -v '^\.critos/memory/'
    mem_ls '.critos/memory/*DECISIONS*.md'; mem_ls '.critos/memory/*LESSONS*.md'
    for o in ${owned[@]+"${owned[@]}"}; do [ -d "$o" ] && git ls-files --others --exclude-standard -- "$o/*DECISIONS*.md" "$o/*LESSONS*.md" 2>/dev/null; done; } | sort -u
}
{ printf '%s\n' "$root"; constellation "$root"; } | while IFS= read -r r21; do
  [ -d "$r21" ] || continue
  if [ "$r21" = "$root" ]; then logs21_home; else { git -C "$r21" ls-files '*DECISIONS*.md' '*LESSONS*.md'; git -C "$r21" ls-files --others --exclude-standard -- '*DECISIONS*.md' '*LESSONS*.md'; } 2>/dev/null | sort -u; fi \
  | while IFS= read -r lg21; do
      if [ "$r21" = "$root" ]; then rd "$lg21"; f21="$RD"; else f21="$r21/$lg21"; fi
      [ -f "$f21" ] || continue
      grep -hoE "^#{1,4}[[:space:]]*$id_re" "$f21" | grep -oE "$id_re"
      awk '/^#{1,4}[[:space:]]*(ADR|L)-[A-Za-z0-9]+-[0-9]/{exit} {print}' "$f21" | grep -oE "$id_re"
    done
done | sort -u > "$declared21"
# retired prefixes: `PREFIX-NNN` on the LEFT of an arrow in a log's head, here and in every
# registered repo. Only the left side retires: the right side of `ADR-OLD-NNN -> ADR-A2-NNN` is
# the LIVE sequence, and retiring it too would silence every typo in a live id.
{ printf '%s\n' "$root"; constellation "$root"; } | while IFS= read -r r21; do
  [ -d "$r21" ] || continue
  if [ "$r21" = "$root" ]; then logs21_home; else git -C "$r21" ls-files '*DECISIONS*.md' '*LESSONS*.md' 2>/dev/null; fi | while IFS= read -r lg21; do
    if [ "$r21" = "$root" ]; then rd "$lg21"; f21="$RD"; else f21="$r21/$lg21"; fi
    [ -f "$f21" ] || continue
    awk '/^#{1,4}[[:space:]]*(ADR|L)-[A-Za-z0-9]+-[0-9]/{exit} {print}' "$f21" \
      | grep -oE '\b(ADR|L)-[A-Za-z0-9]+-NNN\b[`*[:space:]]*(->|→)' | sed -E 's/NNN.*$//'
  done
done | sort -u > "$prefixes21"
if [ ! -s "$declared21" ]; then
  echo "(no decision or lesson log declares an id in this repo — skipped)"
else
  cited21=$(mgrep . -I -hoE "$id_re" -- ':(exclude).critos/system' ':(exclude)*archive*' \
      ':(exclude).claude/skills' ':(exclude).claude/agents/agent-1.md' ':(exclude)skills/crit-*' \
      ':(exclude)*.tmpl' ':(exclude)MEMORY-INDEX.md' | sort -u)
  any21=0
  while IFS= read -r id21; do
    [ -z "$id21" ] && continue
    grep -qxF "$id21" "$declared21" && continue
    if [ -s "$prefixes21" ] && grep -qxF "$(printf '%s' "$id21" | sed -E 's/[0-9]+$//')" "$prefixes21"; then continue; fi
    if [ -n "$exempt_re" ] && printf '%s\n' "$id21" | grep -qE "$exempt_re"; then continue; fi
    where21=$(mgrep . -I -lw -F "$id21" -- ':(exclude).critos/system' ':(exclude)*archive*' ':(exclude)MEMORY-INDEX.md' | head -3 | tr '\n' ' ')
    echo "CITED-ID  $id21 — declared in no decision or lesson log (archives included). Cited in: $where21"
    any21=1
  done <<< "$cited21"
  [ "$any21" = 0 ] && echo "(none — every cited id resolves to a log entry)"
fi
rm -f "$declared21" "$prefixes21"

hdr 22 "ROOTS: every tracked file under a domain's root or a ruled surface; no root declared twice; none matching nothing"
# The roster's Roots column (contract-agent § 1, § 3): backticked paths — a trailing `/` is a
# folder root, any other a file root, `/` alone the whole repo. The most specific path wins, so a
# file root inside another actor's folder is legal and only the SAME root under two actors is an
# OVERLAP. Rooted by construction, never declared: `.critos/system/` (installed),
# `.critos/memory/a<N>/` (the memory invariant), the generated atlas. A ruled surface is a
# backticked path in the write-surface table's first column (a row whose Owner cell names an
# actor); a table or a service named there is not in the tree and is simply never matched.
# Files are read tracked + untracked-not-ignored, like [1]: a new file is read while its author
# is looking, and a newborn scaffold is not DANGLING before its first commit.
# UNROOTED is listed per top-level folder, three names each: the count is the finding.
if [ -z "$ROSTER" ]; then
  echo "(no roster in this repo — skipped)"
else
  roots_col=$(awk -F'|' '$2 ~ /^[[:space:]]*#[[:space:]]*$/ { for(i=1;i<=NF;i++) if (tolower($i) ~ /roots/) {print i; exit} }' "$ROSTER" | head -1)
  if [ -z "$roots_col" ]; then
    echo "SKIPPED  the roster has no Roots column — every domain's place in the tree is unknown to the battery (contract-agent § 3). The column arrives with the migration; each domain's cells with the user's ruling."
  else
    roots22=$(mktemp); surf22=$(mktemp); un22=$(mktemp); any22=0
    shelf_col22=$(awk -F'|' '$2 ~ /^[[:space:]]*#[[:space:]]*$/ { for(i=1;i<=NF;i++) if (tolower($i) ~ /shelf/) {print i; exit} }' "$ROSTER" | head -1)
    rdir22=$(dirname "$ROSTER")
    while IFS= read -r row22; do
      c2=$(printf '%s' "$row22" | awk -F'|' '{gsub(/[^A-Za-z0-9]/,"",$2); print $2}')
      case "$c2" in
        A[0-9]|A[0-9][0-9])   # an actor row: its Roots cell, and the folder of its Shelf index
          printf '%s' "$row22" | awk -F'|' -v c="$roots_col" 'NF>c {print $c}' | grep -oE '`[^`]+`' | tr -d '`' \
            | sed -E 's#^\./##' | awk -v a="$c2" 'NF {print $0 "\t" a}' >> "$roots22"
          # the shelf is a root by construction (contract-agent § 3): the first link of the Shelf cell,
          # resolved from the roster's folder; a shelf at the repo root roots the whole repo. Only a
          # shelf whose index EXISTS: an address that does not resolve is [20]'s finding, once.
          if [ -n "$shelf_col22" ]; then
            sh22=$(printf '%s' "$row22" | awk -F'|' -v c="$shelf_col22" 'NF>c {print $c}' | grep -oE '\]\([^)]+\)' | head -1 | sed -E 's/^\]\(//; s/\)$//')
            case "$sh22" in ''|http://*|https://*|mailto:*|\#*) ;; *)
              sh22=${sh22%%#*}; sh22=${sh22//%20/ }
              t22=$(realpath -m --relative-to=. "$rdir22/$sh22" 2>/dev/null)
              if [ -n "$t22" ] && [ -f "$t22" ]; then
                d22=$(dirname "$t22"); [ "$d22" = "." ] && d22="/" || d22="$d22/"
                printf '%s\t%s\n' "$d22" "$c2" >> "$roots22"
              fi ;;
            esac
          fi ;;
        *)                     # a write-surface row: Owner names an actor (anywhere in the cell), Surface may be a path
          own22=$(printf '%s' "$row22" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); print $3}')
          case "$own22" in *A[0-9]*) ;; *) continue ;; esac
          printf '%s' "$row22" | awk -F'|' '{print $2}' | grep -oE '`[^`]+`' | tr -d '`' | sed -E 's#^\./##' | awk 'NF' >> "$surf22" ;;
      esac
    done < <(grep -E '^\|' "$ROSTER")
    # OVERLAP — the same root under two actors
    while IFS=$'\t' read -r r22 who22; do
      [ -z "$r22" ] && continue
      echo "OVERLAP  $r22 — declared by $who22: one root, one owner (the most specific path wins only between DIFFERENT paths; the same path twice is a collision the roster exists to show)"
      any22=1
    done < <(awk -F'\t' '{ if (!($1 in a)) a[$1]=$2; else if (index(a[$1],$2)==0) a[$1]=a[$1] " + " $2 } END { for (r in a) if (index(a[r]," + ")) print r "\t" a[r] }' "$roots22" | sort)
    # DANGLING — a root matching nothing in the tracked tree
    while IFS=$'\t' read -r r22 who22; do
      [ -z "$r22" ] && continue
      case "$r22" in
        /) continue ;;
        */) [ -n "$(git ls-files --cached --others --exclude-standard -- "$r22" 2>/dev/null | head -1)" ] || { echo "DANGLING  $r22 ($who22) — a folder root matching no file: moved, renamed, or never there"; any22=1; } ;;
        *)  git ls-files --cached --others --exclude-standard -- "$r22" 2>/dev/null | grep -qxF "$r22" || { echo "DANGLING  $r22 ($who22) — a file root matching no file: moved, renamed, or never there"; any22=1; } ;;
      esac
    done < <(sort -u "$roots22")
    # UNROOTED — a tracked file under no root and no ruled surface, grouped by top-level folder
    git ls-files --cached --others --exclude-standard | awk -F'\t' -v R="$roots22" -v S="$surf22" '
      function add(p) { if (p == "/") all = 1; else if (p ~ /\/$/) dirs[p] = 1; else files[p] = 1 }
      BEGIN { while ((getline l < R) > 0) { split(l, parts, "\t"); add(parts[1]) }
              while ((getline l < S) > 0) add(l) }
      { f = $0
        if (all) next
        if (f ~ /^\.critos\/system\//) next
        if (f ~ /^\.critos\/memory\/a[0-9]+\//) next
        if (f ~ /^\.critos\/checks\/a[0-9]+\//) next
        if (f == "MEMORY-INDEX.md") next
        if (f in files) next
        hit = 0; for (d in dirs) if (index(f, d) == 1) { hit = 1; break }
        if (!hit) print f }' \
    | awk -F'/' '{ top = (NF > 1) ? $1 "/" : "(the repo root)"; n[top]++; if (n[top] <= 3) ex[top] = ex[top] (ex[top] ? ", " : "") $0 }
                 END { for (t in n) printf "UNROOTED  %d file(s) under no root and no ruled surface — %s: %s%s\n", n[t], t, ex[t], (n[t] > 3 ? ", …" : "") }' \
    | sort > "$un22"
    if [ -s "$un22" ]; then cat "$un22"; any22=1; fi
    [ "$any22" = 0 ] && echo "(none — every tracked file sits under a domain's root or a ruled surface; no root is declared twice, none matches nothing)"
    rm -f "$roots22" "$surf22" "$un22"
  fi
fi

hdr 23 "INBOX-ACTOR: a live entry whose sender is not a rostered agent, or whose recipient is neither rostered nor AGENT 0"
# The membrane (contract-system § 0): what enters the inbox is a builder's own entry, so every
# sender must be an actor the roster names — AGENT 0 included: it is the reserved address of
# upstream, a recipient only; nobody in the project writes as it (contract-agent § 5). A
# recipient must be rostered or AGENT 0: anything else is a dead address, owed by nobody. The
# participants are read before the first colon, the sender before the arrow, the recipients
# after it, FYI readers included. Live inbox only, SETTLED ENTRIES INCLUDED: an archive is a
# record, and a settled entry from such a sender still in the live inbox is history to rotate —
# the finding is the nudge, not an accusation.
if [ -z "$INBOX" ]; then
  echo "(no live inbox in this repo — skipped)"
elif [ -z "$ROSTER" ]; then
  echo "SKIPPED  the inbox has entries but there is no roster to read their actors against"
else
  rostered23=$(grep -oE '^\|[[:space:]]*A[0-9]+[[:space:]]*\|' "$ROSTER" | grep -oE 'A[0-9]+' | sort -u)
  any23=0
  while IFS= read -r e23; do
    head23=${e23%%:*}
    case "$head23" in *→*) ;; *) continue ;; esac
    date23=$(printf '%s' "$e23" | grep -oE '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' | cut -c3-)
    from23=$(printf '%s' "${head23%%→*}" | grep -oE 'AGENT [0-9]+' | head -1 | sed 's/^AGENT //')
    if [ "$from23" = "0" ]; then
      echo "INBOX-ACTOR  $date23 — sender AGENT 0: the reserved address of upstream RECEIVES a raise, it never writes here (contract-agent § 5); an answer from upstream is a release, or the user's words"
      any23=1
    elif [ -n "$from23" ] && ! printf '%s\n' "$rostered23" | grep -qxF "A$from23"; then
      echo "INBOX-ACTOR  $date23 — sender AGENT $from23 is not in the roster: an entry no rostered actor authored is content with no owner (the membrane, contract-system § 0)"
      any23=1
    fi
    for n23 in $(printf '%s' "${head23#*→}" | grep -oE 'AGENT [0-9]+' | sed 's/^AGENT //' | sort -u); do
      [ "$n23" = 0 ] && continue
      printf '%s\n' "$rostered23" | grep -qxF "A$n23" || { echo "INBOX-ACTOR  $date23 — recipient AGENT $n23 is not in the roster: a dead address, owed by nobody"; any23=1; }
    done
  done < <(grep -E '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$INBOX")
  [ "$any23" = 0 ] && echo "(none — every live entry's sender is a rostered actor, every recipient rostered or AGENT 0)"
  [ "$any23" = 1 ] && echo "               → a settled entry listed above is history: rotate it to the archive (A1); a live one is content with no owner"
fi

hdr 24 "FUTURE-DATE: a stamp later than today (UTC) in a memory log, a STATUS, a register or their archives"
# contract-system § 5: a stamp is taken from date -u at the moment of stamping — the harness
# announces the machine's LOCAL day, which after 22:00 UTC is tomorrow. The registers are
# ORDERED by these dates, so a future one sorts above everything written after it.
# A STAMP lives in a STAMP POSITION, and only those are read — a live project carries the
# future on purpose elsewhere (an expiry, a schedule, a deadline, a reminder), and a check that
# read every date token cried wolf thirty times on zero wrong stamps. The positions, declared:
#   - an inbox entry's head            `- YYYY-MM-DD —`
#   - a lifecycle token's date         `[ABSORBED YYYY-MM-DD` · `[PARKED-OWNED YYYY-MM-DD`
#   - a heading that carries an id     `## ADR-… — … YYYY-MM-DD` · `## L-… (…, YYYY-MM-DD)` — every date on it
#   - a `Last updated:` line           every date on it
#   - a register verdict               `done|closed|parked|superseded|re-verified YYYY-MM-DD`
#   - an aging mark                    `**Marked YYYY-MM-DD` · `**Rotated YYYY-MM-DD` · `**FACT-FLIP YYYY-MM-DD`
# Bound, declared: a wrong stamp written anywhere else (prose, a cell) is not seen.
today24=$(date -u +%F)
files24=$( { mem_ls '.critos/memory/*.md'; git ls-files '.critos/shared/*.md' 2>/dev/null; } | sort -u)
if [ -z "$files24" ]; then
  echo "(no memory log, STATUS or register in this repo — skipped)"
else
  out24=$(while IFS= read -r f24; do
    rd "$f24"; [ -f "$RD" ] || continue
    # The leg patterns are STRINGS, not regexp constants: a `/…/` passed as a function argument
    # is evaluated by gawk as `$0 ~ /…/` and arrives as 0 or 1 — three legs once searched a digit
    # and could not go red. Each leg has its own positive in the fixture; `Last updated:` is read
    # only at a line's start, so an entry that QUOTES the phrase is not read.
    awk -v today="$today24" -v f="$f24" '
      BEGIN { D = "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
              RE_TOKEN = "\\[(ABSORBED|PARKED-OWNED)[[:space:]]+" D
              RE_VERDICT = "(done|closed|parked|superseded|re-verified|DONE|CLOSED|PARKED|SUPERSEDED)[[:space:]]+" D
              RE_MARK = "\\*\\*(Marked|Rotated|FACT-FLIP)[[:space:]]+" D }
      function chk(d) { if (d > today && !seen[NR SUBSEP d]++) printf "FUTURE-DATE  %s:%d  %s — a stamp later than today (%s UTC): taken from the harness'"'"'s local day, not from date -u (contract-system § 5); the registers sort by it\n", f, NR, d, today }
      function all(s) { while (match(s, D)) { chk(substr(s, RSTART, RLENGTH)); s = substr(s, RSTART + RLENGTH) } }
      function after(s, re,   m) { if (match(s, re)) { m = substr(s, RSTART, RLENGTH); if (match(m, D)) chk(substr(m, RSTART, RLENGTH)) } }
      /^- 20[0-9][0-9]-[0-9][0-9]-[0-9][0-9][[:space:]]/ { chk(substr($0, 3, 10)) }
      /^#{1,4}[[:space:]]/ && /(ADR|L)-[A-Za-z0-9]+-[0-9]/ { all($0) }
      /^[*_[:space:]]*[Ll]ast updated:/ { all($0) }
      { after($0, RE_TOKEN); after($0, RE_VERDICT); after($0, RE_MARK) }
    ' "$RD"
  done <<< "$files24")
  if [ -n "$out24" ]; then printf '%s\n' "$out24"; else echo "(none — no stamp later than $today24 UTC in a stamp position; dates in prose are not read)"; fi
fi

hdr 25 "FORMS: the rotation pointer and the archive's name, as the method writes them"
# contract-memory § 2 fixes two forms the controls read. POINTER-FORM: a line of a live memory
# log that marks a rotation — a list line carrying the word ROTATED, or a heading in the stub's
# form (`— ROTATED YYYY-MM-DD to`: a title that names the word is an entry), outside a fence; a
# sentence of prose that names the word is not read — in any shape but
#   - `<id>` — ROTATED YYYY-MM-DD to archive/<file> (<state>)
# with the state one of `done` · `superseded by <id>` · `consolidated in <id>`; a heading is not a
# pointer, a fourth state is not a state. ARCHIVE-NAME: a file under `.critos/memory/a<N>/archive/`
# outside the two names, DECISIONS-archive-YYYY-MM.md and LESSONS-LEARNED-archive-YYYY-MM.md —
# a day file, a range, an older prefix, a STATUS (never archived).
any25=0
idtok="\`?($id_core)\`?"
ptr_ok="^- $idtok — ROTATED 20[0-9]{2}-[0-9]{2}-[0-9]{2} to archive/(DECISIONS|LESSONS-LEARNED)-archive-20[0-9]{2}-[0-9]{2}\.md \((done|superseded by $idtok|consolidated in $idtok)\)$"
while IFS= read -r lg; do
  rd "$lg"; [ -f "$RD" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    ln25=${hit%%:*}; line25=${hit#*:}
    printf '%s' "$line25" | grep -Eq "$ptr_ok" && continue
    echo "POINTER-FORM  $lg:$ln25  $(printf '%s' "$line25" | cut -c1-90)$(born 1.2.0)"
    any25=1
  done < <(awk -v ROT="$rot_re" '/^[[:space:]]*```/{f=!f;next} !f && ((/^- / && /(^|[^A-Za-z])ROTATED([^A-Za-z]|$)/) || (/^#{1,4}[[:space:]]/ && $0 ~ ROT)){print NR ":" $0}' "$RD")
done < <(logs12)
while IFS= read -r af; do
  [ -z "$af" ] && continue
  printf '%s' "$(basename "$af")" | grep -Eq '^(DECISIONS|LESSONS-LEARNED)-archive-20[0-9]{2}-[0-9]{2}\.md$' && continue
  echo "ARCHIVE-NAME  $af  (the archive is the log's own name, one file per month: DECISIONS-archive-YYYY-MM.md · LESSONS-LEARNED-archive-YYYY-MM.md; a STATUS is never archived)$(born 1.2.0)"
  any25=1
done < <(mem_ls '.critos/memory/a*/archive/*')
[ "$any25" = 0 ] && echo "(none — every pointer in shape with a state of the three, every archive under the log's name by month)"

hdr 26 "CARRIES: every live entry carries its rule; nothing in force left the live log without a live carrier"
# contract-memory § 2. The `Carries` block of a live entry is read by the in-force control
# (`in-force.sh --lines`: one parser for the index and for this check). NO-CARRIER — a live entry
# with no line for its own id; CARRIES-FORM — a line under the block outside the two shapes, or a
# settled state outside the three; UNCARRIED — an id headed in an archive with no live carrier
# (no pointer in the live log, no Carries line of a live entry; a pointer `consolidated in <id>`
# needs a binds: line somewhere live); CARRIER-CONFLICT — one id carried as in force and as
# settled at once (a pointer consolidated in a live entry is not settled: the binds: line it
# demands is its carrier); TWO-HOMES — an id has one home, the folder whose archive heads it:
# headed in two folders' archives, or pointed from a folder whose own archive does not head it.
# Pointers are read per folder, and UNCARRIED lands on the pointer that demands, at its line.
# Fenced blocks are not read: a log's head shows the shape inside a fence.
inforce="$here/../crit-in-force/in-force.sh"
if [ ! -f "$inforce" ]; then
  echo "SKIPPED — the in-force control is not beside this one ($inforce): the Carries blocks cannot be read (NOT a clean none)"
else
  lines26=$(mktemp); ptr26=$(mktemp); heads26=$(mktemp); two26=$(mktemp); out26=$(mktemp)
  err26=$(bash "$inforce" ${own_args[@]+"${own_args[@]}"} --lines 2>&1 > "$lines26"); rc26=$?
  if [ "$rc26" != 0 ]; then echo "SKIPPED — the in-force control could not read the Carries lines (exit $rc26: ${err26:-no message}) — NOT a clean none"; rm -f "$lines26" "$ptr26" "$heads26" "$two26" "$out26"; else
  # the pointers of every live log, per folder: folder <TAB> id <TAB> settled|consolidated <TAB> log:line
  while IFS= read -r lg; do
    rd "$lg"; [ -f "$RD" ] || continue
    case "$lg" in *-archive-*|*/archive/*) continue ;; esac
    awk -v IDC="$id_core" -v ROT="$rot_re" -v f="$lg" -v d="$(dirname "$lg")" '/^[[:space:]]*```/{fence=!fence;next} !fence && /^- `?[^`]*`? — ROTATED / { if (match($0, IDC)) { id = substr($0, RSTART, RLENGTH); st = "settled"; if ($0 ~ /\(consolidated in /) st = "consolidated"; print d "\t" id "\t" st "\t" f ":" NR } }' "$RD"
  done < <(logs12) | sort -u > "$ptr26"
  # the ids headed in every archive, per folder: folder <TAB> id <TAB> archive (a heading in the
  # stub's form, `— ROTATED YYYY-MM-DD to`, is a stub of the old pointer shape, never an entry: not
  # read here; a title that names the word is read as the entry it is)
  while IFS= read -r af; do
    rd "$af"; [ -f "$RD" ] || continue
    awk -v IDC="$id_core" -v ROT="$rot_re" -v a="$af" -v d="${af%/archive/*}" '$0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); print d "\t" substr($0, RSTART, RLENGTH) "\t" a }' "$RD"
  done < <(mem_ls '.critos/memory/a*/archive/*.md') | sort -u > "$heads26"
  # NO-CARRIER, per live entry
  while IFS= read -r lg; do
    rd "$lg"; [ -f "$RD" ] || continue
    case "$lg" in *-archive-*|*/archive/*) continue ;; esac
    while IFS= read -r ent; do
      [ -n "$ent" ] || continue
      ln26=${ent%%:*}; id26=${ent#*:}
      awk -F'\t' -v f="$lg" -v e="$id26" '$1 == f && $3 == e && $4 == e && ($5 == "binds" || $5 == "settled")' "$lines26" | grep -q . \
        || echo "NO-CARRIER  $lg:$ln26  $id26 — a live entry carries at least its own rule: one line under **Carries.** (binds: <lane>, or settled: <state>)$(born 1.2.0)" >> "$out26"
    done < <(awk -v IDC="$id_core" -v ROT="$rot_re" '/^[[:space:]]*```/{f=!f;next} !f && $0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); print NR ":" substr($0, RSTART, RLENGTH) }' "$RD")
  done < <(logs12)
  # (a heading in the stub's form is a pointer in the wrong shape — [25]'s finding, not an entry)
  # CARRIES-FORM, per line read
  while IFS=$'\t' read -r f26 l26 e26 id26 k26 v26 t26 d26 r26; do
    case "$k26" in
      bad) echo "CARRIES-FORM  $f26:$l26  $(printf '%s' "$v26" | cut -c1-80) — the shape: - \`<id>\` · <rule> · binds: <lane>[ · tier N[ — <detector>]]  or  · settled: <state>[ — <why>]$(born 1.2.0)" >> "$out26" ;;
      settled) printf '%s' "$v26" | grep -Eq "^(done|superseded by \`?($id_core)\`?|consolidated in \`?($id_core)\`?)( — .*)?$" \
                 || echo "CARRIES-FORM  $f26:$l26  settled: $(printf '%s' "$v26" | cut -c1-60) — the state is one of done · superseded by <id> · consolidated in <id>$(born 1.2.0)" >> "$out26" ;;
    esac
  done < "$lines26"
  # UNTIERED: a rule in force declares its tier — on its line, or by its entry's Enforcement:
  # field; a binds: line with neither prints `tier ?` in the index and is a finding on the line
  awk -F'\t' '$5 == "binds" && $7 == "?" { print $1 ":" $2 "\t" $4 }' "$lines26" \
    | while IFS=$'\t' read -r uw uid; do
        [ -n "$uid" ] && echo "UNTIERED  $uw  $uid — a rule in force declares its tier: \`tier N\` on the line, or the entry's **Enforcement:** field; this line has neither, and the index prints tier ?$(born 1.2.0)" >> "$out26"
      done
  # TWO-HOMES: an id has one home — the folder whose archive heads it. Headed in two folders'
  # archives (a copied entry), or pointed from a folder whose own archive does not head it (the
  # mark is the owner's; a split's new owner carries what it inherits in its founding block)
  awk -F'\t' '{ k = $2; if (index(h[k], "\t" $1 "\t") == 0) { h[k] = h[k] "\t" $1 "\t"; n[k]++ } } END { for (k in h) if (n[k] > 1) { gsub(/\t\t/, ", ", h[k]); gsub(/^\t|\t$/, "", h[k]); print k "\t" h[k] } }' "$heads26" | sort > "$two26"
  while IFS=$'\t' read -r tid tf; do
    [ -n "$tid" ] && echo "TWO-HOMES  $tid — headed in the archives of two folders ($tf): an id has one home, the folder whose archive heads it; a copy of an entry is not a second home$(born 1.2.0)" >> "$out26"
  done < "$two26"
  # The declared home of a family (`<regex> · home: a<N>` in id-families): a heading of the family
  # in a folder other than its home — an archive's or a live log's — is a finding from the first
  # heading, with no second archive to compare; a declared home that is no memory folder is a
  # finding on the line. The declaration is a claim the control reads, never an exemption; an
  # undeclared family's home stays derived from the archives.
  if [ -f .critos/project/id-families ]; then
    while IFS= read -r hl; do
      [ -n "$hl" ] || continue
      hln=${hl%%:*}; hbody=${hl#*:}
      hre=$(printf '%s' "$hbody" | sed -E 's/[[:space:]]*·[[:space:]]*home:.*$//')
      hhome=$(printf '%s' "$hbody" | sed -E 's/^.*home:[[:space:]]*//; s/[[:space:]]+$//')
      if ! printf '%s' "$hhome" | grep -qE '^a[0-9]+$' || [ ! -d ".critos/memory/$hhome" ]; then
        echo "TWO-HOMES  .critos/project/id-families:$hln  $(printf '%s' "$hbody" | cut -c1-60) — the declared home \`$hhome\` is not a memory folder (.critos/memory/a<N>/): a family's home is a folder that exists$(born 1.2.0)" >> "$out26"
        continue
      fi
      { awk -F'\t' -v re="$hre" -v home=".critos/memory/$hhome" '$2 ~ re && $1 != home { print $3 "\t" $2 "\t" $1 }' "$heads26"
        while IFS= read -r lg; do
          rd "$lg"; [ -f "$RD" ] || continue
          case "$lg" in *-archive-*|*/archive/*) continue ;; esac
          [ "$(dirname "$lg")" = ".critos/memory/$hhome" ] && continue
          awk -v IDC="$id_core" -v ROT="$rot_re" -v re="$hre" -v f="$lg" -v d="$(dirname "$lg")" '/^[[:space:]]*```/{fence=!fence;next} !fence && $0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); id = substr($0, RSTART, RLENGTH); if (id ~ re) print f ":" NR "\t" id "\t" d }' "$RD"
        done < <(logs12); } | sort -u \
      | while IFS=$'\t' read -r hwhere hid hfold; do
          [ -n "$hid" ] && echo "TWO-HOMES  $hwhere  $hid — headed in $hfold/, outside the family's declared home ($hhome, id-families:$hln): an id has one home, and a declared family is headed in its home only$(born 1.2.0)" >> "$out26"
        done
    done < <(grep -nE '·[[:space:]]*home:' .critos/project/id-families | grep -vE '^[0-9]+:[[:space:]]*#')
  fi
  while IFS=$'\t' read -r pf pid pst ploc; do
    [ -n "$pid" ] || continue
    awk -F'\t' -v d="$pf" -v i="$pid" '$1 == d && $2 == i' "$heads26" | grep -q . && continue
    echo "TWO-HOMES  $ploc  $pid — pointed from $pf/, whose archive does not head it: an id is pointed from its home only, the folder whose archive heads it (the mark is the owner's; a split's new owner carries what it inherits in its founding block, never by pointer)$(born 1.2.0)" >> "$out26"
  done < "$ptr26"
  # HEADED-TWICE: one id, one heading inside its home. The headings of a folder's live logs and
  # archives together, a heading in the stub's form excluded: an id headed more than once in one
  # folder is a finding naming the places. An increment written as a heading (ADDENDUM, STEP n,
  # AMENDED) is a dated line in the entry's body or a new entry; a stub of the old pointer form is
  # deleted, never archived; two entries under one string are the collision the owner tells apart.
  all26=$(mktemp)
  { while IFS= read -r lg; do
      rd "$lg"; [ -f "$RD" ] || continue
      case "$lg" in *-archive-*|*/archive/*) continue ;; esac
      awk -v IDC="$id_core" -v ROT="$rot_re" -v f="$lg" -v d="$(dirname "$lg")" '/^[[:space:]]*```/{fence=!fence;next} !fence && $0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); print d "\t" substr($0, RSTART, RLENGTH) "\t" f ":" NR }' "$RD"
    done < <(logs12)
    while IFS= read -r af; do
      rd "$af"; [ -f "$RD" ] || continue
      awk -v IDC="$id_core" -v ROT="$rot_re" -v f="$af" -v d="${af%/archive/*}" '$0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); print d "\t" substr($0, RSTART, RLENGTH) "\t" f ":" NR }' "$RD"
    done < <(mem_ls '.critos/memory/a*/archive/*.md'); } | sort -u > "$all26"
  awk -F'\t' '{ k = $1 "\t" $2; n[k]++; w[k] = w[k] (w[k] ? ", " : "") $3 } END { for (k in n) if (n[k] > 1) print k "\t" n[k] "\t" w[k] }' "$all26" | sort \
    | while IFS=$'\t' read -r hf hid hn hw; do
        echo "HEADED-TWICE  $hid — headed $hn times in $hf/ ($hw): one id, one heading inside its home — an amendment is a dated line in the entry's body (**Amended YYYY-MM-DD (<id>):**) or a new entry that cites it; a stub of the old pointer form is deleted, never archived$(born 1.2.0)" >> "$out26"
      done
  rm -f "$all26"
  # UNCARRIED, per id headed in an archive, read against its home's pointer: a pointer settled
  # carries it; a pointer consolidated needs a binds: line of a live entry, in any folder (a
  # split's founding block lives elsewhere); no pointer needs a Carries line of a live entry.
  # The finding lands on the pointer that demands, at its line — on the archive when no pointer
  # exists. An id with two homes is reported above, not here.
  while IFS=$'\t' read -r hf hid ha; do
    [ -n "$hid" ] || continue
    awk -F'\t' -v i="$hid" '$1 == i' "$two26" | grep -q . && continue
    st26=$(awk -F'\t' -v d="$hf" -v i="$hid" '$1 == d && $2 == i {print $3; exit}' "$ptr26")
    loc26=$(awk -F'\t' -v d="$hf" -v i="$hid" '$1 == d && $2 == i {print $4; exit}' "$ptr26")
    [ "$st26" = settled ] && continue
    if [ "$st26" = consolidated ]; then
      awk -F'\t' -v i="$hid" '$4 == i && $5 == "binds"' "$lines26" | grep -q . && continue
      echo "UNCARRIED  $loc26  $hid — its pointer says consolidated, and no live entry carries a binds: line for it (headed in $ha)$(born 1.2.0)" >> "$out26"; continue
    fi
    awk -F'\t' -v i="$hid" '$4 == i && ($5 == "binds" || $5 == "settled")' "$lines26" | grep -q . && continue
    echo "UNCARRIED  $hid — headed in $ha and carried by nothing live: no pointer in $hf/, no Carries line (nothing leaves the live log without a live carrier)$(born 1.2.0)" >> "$out26"
  done < "$heads26"
  # CARRIER-CONFLICT: in force and settled at once — a binds: line against a settled: line, or
  # against the home's pointer in state done or superseded (a consolidated pointer is not
  # settled; a pointer outside its home is TWO-HOMES, not a disposition)
  { awk -F'\t' '$4 != "" && ($5 == "binds" || $5 == "settled") {print $4 "\t" $5}' "$lines26"
    awk -F'\t' 'NR == FNR { home[$1 "\t" $2] = 1; next } $3 == "settled" && (($1 "\t" $2) in home) { print $2 "\tsettled" }' "$heads26" "$ptr26"; } | sort -u \
    | awk -F'\t' '{ s[$1] = s[$1] $2 ";" } END { for (i in s) if (index(s[i], "binds;") && index(s[i], "settled;")) print i }' | sort \
    | while IFS= read -r cid; do echo "CARRIER-CONFLICT  $cid — carried as in force (binds:) and as settled (a pointer, or a settled: line) at once: one disposition per id$(born 1.2.0)" >> "$out26"; done
  if [ -s "$out26" ]; then cat "$out26"; else echo "(none — every live entry carries its own rule, every archived id has one home and a live carrier, no id is carried two ways)"; fi
  rm -f "$lines26" "$ptr26" "$heads26" "$two26" "$out26"
  fi
fi

hdr 27 "IN-FORCE: the generated law in force of every agent is fresh, and within its budget"
# contract-memory § 6: IN-FORCE.md is derived from the folder's logs by the in-force control;
# its --check compares the file on disk with a fresh generation (the stamp line excepted) and
# reads the budget. IN-FORCE-STALE — missing, or differs: the boot would read a law that is not
# the logs'; IN-FORCE-BUDGET (WARN) — past the budget: consolidate.
if [ ! -f "$inforce" ]; then
  echo "SKIPPED — the in-force control is not beside this one ($inforce): the indexes cannot be checked (NOT a clean none)"
else
  out27=$(bash "$inforce" ${own_args[@]+"${own_args[@]}"} --check 2>&1); rc27=$?
  if [ "$rc27" = 2 ]; then
    echo "SKIPPED — the in-force control could not run: $(printf '%s' "$out27" | head -1) — NOT a clean none"
  elif printf '%s\n' "$out27" | grep -qE '^(STALE|BUDGET)'; then
    b27=$(born 1.2.0)
    printf '%s\n' "$out27" | sed -nE "s/^STALE  (.*)$/IN-FORCE-STALE  \1$b27/p; s/^BUDGET  (.*)$/IN-FORCE-BUDGET  \1/p"
  elif printf '%s\n' "$out27" | grep -q '^(no memory folder'; then
    printf '%s\n' "$out27"
  else
    echo "(none — $(printf '%s\n' "$out27" | grep -c '^FRESH') index(es) fresh, within budget)"
  fi
fi

hdr 28 "DETECTOR: every tier-2 claim names a detector that exists; every detector is in its agent's folder, with its head"
# contract-session § 6. A tier-2 claim — an Enforcement line whose field says tier 2 at its head
# (a tier-3 field that mentions tier 2 later is not a claim), or a Carries line with tier 2 —
# resolves either to a leg of the product's controls named by its stable name (the list below:
# every finding token of this battery, the controls, the guards — one name per line, matched
# whole: a word of a name is not the name, a number alone is not a name) or to a file under
# `.critos/checks/a<N>/` whose head names the id (`Enforces:`).
# TIER-2-UNDETECTED — a claim neither resolves. DETECTOR-HEAD — a file under `.critos/checks/`
# outside `a<N>/`, or without `Enforces: <id>` in its first lines, or whose head runs a machine
# path (a command in another repository names it as `.claude/repos` declares it).
# DETECTOR-CROSS-IMPORT — a detector that reaches into another agent's folder.
# (Keep the list in step with the header above when a token is added.)
product_legs=(
  BROKEN TRACKED-MISSING PATH-IN-CODE ORPHAN ORPHAN-BY-USE DANGLING-SKILL PING-PONG NO-DONE-WHEN MULTI-OWNER STALE-Rx
  BAD-TOKEN UNBOLDED-TOKEN STATUS-CHRONICLE NOTE-CHRONICLE STALE-STATUS STALE-STAMP DANGLING-WIKI-LINK AUTO-MEMORY-CITED
  TIER-3-LESSON BAD-BOUND ENFORCEMENT-FORM UNROTATED-LOG DECLARED-OVER ARCHIVABLE MEMORY-SHAPE PIN-DRIFT
  VERSION-SPLIT DEFINITION-PATH RETIRED-REF COLD-LIVE-TOKEN DEFINITION-SHAPE DEFINITION-ACTOR SHELF-INDEX
  CITED-ID UNROOTED OVERLAP DANGLING INBOX-ACTOR FUTURE-DATE POINTER-FORM ARCHIVE-NAME NO-CARRIER
  CARRIES-FORM UNCARRIED CARRIER-CONFLICT TWO-HOMES HEADED-TWICE UNTIERED IN-FORCE-STALE IN-FORCE-BUDGET TIER-2-UNDETECTED DETECTOR-HEAD
  DETECTOR-CROSS-IMPORT
  crit-doc-lint doc-lint "the battery" crit-status-check status-check inbox-check
  crit-memory-index memory-index "the atlas" crit-in-force in-force
  guard-user-driven-actions guard-inbox "the push guard" "the inbox guard" "the guards"
)
heads28=$(mktemp); out28=$(mktemp)
# the detectors: folder, file, the ids its head enforces
while IFS= read -r df; do
  [ -n "$df" ] && [ -f "$df" ] || continue
  case "$df" in
    .critos/checks/a[0-9]*/*) ;;
    *) echo "DETECTOR-HEAD  $df — a detector lives in its agent's folder, .critos/checks/a<N>/ (one writer, rooted by construction)$(born 1.2.0)" >> "$out28"; continue ;;
  esac
  own28=$(printf '%s' "$df" | sed -E 's#^\.critos/checks/a([0-9]+)/.*#\1#')
  enf28=$(head -n 12 "$df" | grep -oE 'Enforces:[[:space:]]*.*' | head -1 | sed -E 's/^Enforces:[[:space:]]*//')
  if [ -z "$enf28" ]; then
    echo "DETECTOR-HEAD  $df — no \`Enforces: <id>, <id>\` in its first lines: the rule it detects is unreadable, so no tier-2 claim resolves to it$(born 1.2.0)" >> "$out28"
  else
    printf '%s' "$enf28" | grep -oE "$id_re" | sed "s|^|$df\t|" >> "$heads28"
  fi
  head -n 12 "$df" | grep -qE '(^|[[:space:]])(Runs|Repo):[[:space:]]*.*([A-Za-z]:[\\/]|/(c|home|Users)/)' \
    && echo "DETECTOR-HEAD  $df — its head runs a machine path: a command in another repository of the project is named as .claude/repos declares it (TARGET)$(born 1.2.0)" >> "$out28"
  grep -nE "\.critos/checks/a[0-9]+/" "$df" | grep -vE "\.critos/checks/a${own28}/" | head -1 | sed -E "s|^([0-9]+):.*|DETECTOR-CROSS-IMPORT  $df:\1 — reaches into another agent's folder: a detector imports nothing from a neighbour (one address, one owner)$(born 1.2.0)|" >> "$out28"
done < <( { git ls-files '.critos/checks/*'; git ls-files --others --exclude-standard -- '.critos/checks/*'; } 2>/dev/null | sort -u)
# the tier-2 claims: Enforcement lines and Carries lines (both logs, live entries only)
claims28=$(mktemp)
while IFS= read -r lg; do
  rd "$lg"; [ -f "$RD" ] || continue
  case "$lg" in *-archive-*|*/archive/*) continue ;; esac
  awk -v IDC="$id_core" -v ROT="$rot_re" -v f="$lg" '
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    $0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && $0 !~ ROT { match($0, IDC); entry = substr($0, RSTART, RLENGTH); next }
    entry != "" && /^(-[[:space:]]+)?[*_]{0,2}[Ee]nforcement[*_]{0,2}:/ {
      d = $0; sub(/^[^:]*:[*_]*[[:space:]]*/, "", d)
      if (d ~ /^[Tt]ier[ -]?2([^0-9]|$)/) { sub(/^[Tt]ier[ -]?2[^A-Za-z]*/, "", d); printf "%s\t%d\t%s\t%s\n", f, NR, entry, d } }
  ' "$RD"
done < <(logs12) > "$claims28"
# the line claims, read as [26] reads them: with the owner — the runner's lines from the tree, every
# other folder as committed; a bare call read every folder at HEAD and missed the runner's own round
[ -f "$inforce" ] && bash "$inforce" ${own_args[@]+"${own_args[@]}"} --lines 2>/dev/null | awk -F'\t' '$5 == "binds" && $7 == "2" { printf "%s\t%s\t%s\t%s\n", $1, $2, $4, $8 }' >> "$claims28"
while IFS=$'\t' read -r f28 l28 id28 det28; do
  [ -n "$id28" ] || continue
  hit=0
  for leg in "${product_legs[@]}"; do
    printf '%s' "$det28" | grep -qwF -- "$leg" && { hit=1; break; }
  done
  [ "$hit" = 1 ] && continue
  awk -F'\t' -v i="$id28" '$2 == i' "$heads28" | grep -q . && continue
  echo "TIER-2-UNDETECTED  $f28:$l28  $id28 — claims tier 2 and names no detector that exists: a leg of the product by its stable name, whole, or a file under .critos/checks/a<N>/ whose head says Enforces: $id28 (a word of a name is not the name; a number alone is not a name)$(born 1.2.0)" >> "$out28"
done < "$claims28"
if [ -s "$out28" ]; then sort -u "$out28"; else echo "(none — every tier-2 claim resolves to a detector, every detector in its folder with its head)"; fi
rm -f "$heads28" "$out28" "$claims28"
[ -n "$t_n" ] && echo "(elapsed [$t_n]: $(( $(date +%s) - t_prev ))s)"
echo
echo "### doc-lint done — 28 checks in $(( $(date +%s) - t_start ))s · controls: CritOS@${ctl_rev:-unversioned}${ctl_dirty:-}"

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
    (cd "$r" && DOC_LINT_NO_CONSTELLATION=1 DOC_LINT_CHILD=1 bash "$self_abs" ${own_args[@]+"${own_args[@]}"})
  done < <(constellation "$root")
fi
