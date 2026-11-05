#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# in-force — generate IN-FORCE.md, the law in force of one agent: one line per rule that binds,
# read from the `Carries` blocks of the live entries of its two logs (contract-memory § 2, § 6).
#
# The boot reads this file, never the logs whole: a log is the chronicle, opened at an id this
# file names. It is DERIVED — a hand-edit disappears at the next run — and it holds the rules
# in force only: a settled rule resolves through the atlas. Grouped by lane; a lane may be
# hierarchical (`onboarding/config`), and a view per lane prefix can be emitted beside the index,
# one section per sub-lane under a stable anchor. Its head counts the live entries it read and
# names those that carry nothing (`Carried: k of N`, then `Uncarried:` per log): the boot opens
# the named entries whole — an index that cannot summarise an entry sends the reader to it, and
# never reads as "no rule binds you" while such an entry exists.
#
# The line it reads, inside a live entry, under a line that is exactly `**Carries.**`:
#   - `<id>` · <the rule in one imperative line> · binds: <lane>[ · tier N[ — <detector>]]
#   - `<id>` · <the rule in one imperative line> · settled: <state>[ — <why>]
# A tier on the line wins; absent, the entry's `**Enforcement:** tier N` field; absent both, `?` —
# a finding of the carrier check (UNTIERED), counted in the head. The field's detector is lent
# to a line only with its tier: a line with its own tier and no detector prints the tier alone.
#
# Usage:  bash ~/.claude/skills/crit-in-force/in-force.sh [--check | --lines] [--own a<N>]... [--lane <prefix>] [<memory-folder>...]
#           --own a<N>       the runner's folder (repeatable; a folder argument counts as one): read from
#                            the working tree and the only ones written. Every other folder is read as
#                            committed (HEAD) and never written; without a name, nothing is written and
#                            every folder is read at HEAD. An unchanged index is not rewritten.
#           (no args)        rewrite IN-FORCE.md in every `.critos/memory/a<N>/` that holds a log,
#                            and every lane view (IN-FORCE.<prefix>.md) already present beside it
#           --lane <prefix>  also emit IN-FORCE.<prefix>.md: the rules whose lane is `<prefix>` or
#                            starts with `<prefix>/`, one section per sub-lane
#           --check          write nothing; per index say FRESH, STALE (differs from a fresh
#                            generation, or missing) or BUDGET (past 300 lines, a warning;
#                            `.claude/doc-lint-in-force-lines` overrides).
#                            exit 1 = at least one STALE · 0 = every index fresh · 2 = cannot run
#           --lines          write nothing; print every `Carries` line parsed, one per line, as
#                            tab-separated fields: log · line · entry id · id · kind (binds,
#                            settled, bad) · value (the lane, the state, or the raw line) · tier ·
#                            detector · the rule. The battery's carrier check reads this.
set -uo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "in-force: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1

mode=write; lanes=(); folders=(); own=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode=check; shift ;;
    --lines) mode=lines; shift ;;
    --lane) lanes+=("$2"); shift 2 ;;
    --own) own+=("$2"); shift 2 ;;
    --me) own+=("a$2"); shift 2 ;;    # the controls' shared convention: --me <N> is --own a<N>
    --domain) shift 2 ;;             # shared convention too; not ours
    -*) echo "in-force: unknown option $1" >&2; exit 2 ;;
    *) folders+=("${1%/}"); shift ;;
  esac
done
budget=300
[ -f .claude/doc-lint-in-force-lines ] && budget=$(grep -oE '^[0-9]+' .claude/doc-lint-in-force-lines | head -1)
: "${budget:=300}"
stamp=${CRITOS_SCAFFOLD_DATE:-$(date -u +%Y-%m-%d)}

# the id grammar: the method's, plus the families the project declares (contract-memory § 2);
# a family line may name its home after the regex (`· home: a2`) — stripped before reading
id_core='(ADR|L)-[A-Za-z0-9]+-[0-9]{3,}'
if [ -f .critos/project/id-families ]; then
  fam=$(grep -vE '^[[:space:]]*(#|$)' .critos/project/id-families | sed -E 's/[[:space:]]*·[[:space:]]*home:.*$//; s/^\^//; s/\$$//' | paste -sd'|' -)
  [ -n "$fam" ] && id_core="$id_core|$fam"
fi


# Owned folders: the runner's, read from the working tree and the only ones written; every other
# memory folder is read as committed (HEAD) and never written — a generator cannot carry another
# owner's uncommitted state (contract-memory § 6). The runner names its folders (--own a<N>, or a
# folder argument); without a name every folder is read at HEAD. A repository with no commit yet
# has nothing that could be another's: its tree is read.
owned=()
for o in ${own[@]+"${own[@]}"} ${folders[@]+"${folders[@]}"}; do
  o=${o%/}; case "$o" in a[0-9]*) o=".critos/memory/$o" ;; esac; owned+=("$o")
done
head_ok=1; git rev-parse -q --verify HEAD >/dev/null 2>&1 || head_ok=0
head_root=$(mktemp -d); trap 'rm -rf "$head_root"' EXIT
is_owned() {   # $1 = a folder, or anything under it (its archive, its notes): owned with its memory folder
  local x t; t=$(printf '%s' "$1" | sed -nE 's#^(\.critos/memory/[^/]+)(/.*)?$#\1#p'); [ -n "$t" ] || t="$1"
  for x in ${owned[@]+"${owned[@]}"}; do [ "$x" = "$t" ] && return 0; done; return 1
}
materialize() {   # $1 = folder -> its HEAD copy under $head_root, once (nothing at HEAD: an empty copy).
                  # Called up front, never inside a command substitution: a subshell's copy dies with it.
  [ -d "$head_root/$1" ] && return 0
  mkdir -p "$head_root/$1"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    mkdir -p "$head_root/$(dirname "$p")"; git show "HEAD:$p" > "$head_root/$p" 2>/dev/null
  done < <(git ls-tree -r --name-only HEAD -- "$1" 2>/dev/null)
}
src_of() {   # $1 = folder -> the directory it is read from: itself when owned, its HEAD copy otherwise
  if [ "$head_ok" = 0 ] || is_owned "$1"; then printf '%s' "$1"; else printf '%s' "$head_root/$1"; fi
}

# the folders: the ones named, else every folder with a log — at HEAD, plus the owned ones in the tree
if [ "${#folders[@]}" = 0 ]; then
  while IFS= read -r f; do [ -n "$f" ] && folders+=("$f"); done < <(
    { if [ "$head_ok" = 1 ]; then
        git ls-tree -r --name-only HEAD -- '.critos/memory/' 2>/dev/null | grep -E '^\.critos/memory/a[0-9]+/(DECISIONS|LESSONS-LEARNED)\.md$'
        for o in ${owned[@]+"${owned[@]}"}; do
          git ls-files "$o/DECISIONS.md" "$o/LESSONS-LEARNED.md"
          git ls-files --others --exclude-standard -- "$o/DECISIONS.md" "$o/LESSONS-LEARNED.md"
        done
      else
        git ls-files '.critos/memory/*/DECISIONS.md' '.critos/memory/*/LESSONS-LEARNED.md'
        git ls-files --others --exclude-standard -- '.critos/memory/*/DECISIONS.md' '.critos/memory/*/LESSONS-LEARNED.md'
      fi; } 2>/dev/null \
    | sed -E 's#/[^/]+$##' | grep -E '^\.critos/memory/a[0-9]+$' | sort -u)
fi
# the HEAD copies of the folders not owned, made once, before anything reads them
if [ "$head_ok" = 1 ]; then for d in ${folders[@]+"${folders[@]}"}; do is_owned "$d" || materialize "$d"; done; fi

# parse_lines LOG — every `Carries` line of a live entry, tab-separated (see --lines). The entry's
# `Enforcement:` field may sit before or after the block, so lines are held and emitted when the
# entry ends. Fenced blocks are skipped: a log's head shows the shape inside a fence.
parse_lines() {   # $1 = the file read, $2 = the path it is reported as (the folder's own, when read at HEAD)
  awk -v IDC="$id_core" -v F="${2:-$1}" '
    function flush(   i, t, d) {
      for (i = 1; i <= n; i++) {
        t = P_tier[i]; if (t == "") t = etier; if (t == "") t = "?"
        d = P_det[i]; if (d == "" && P_tier[i] == "") d = edet
        printf "%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", F, P_ln[i], entry, P_id[i], P_kind[i], P_val[i], t, d, P_rule[i]
      }
      n = 0
    }
    BEGIN { H = "^#{1,4}[[:space:]]*`?(" IDC ")`?"; PRE = "^- `?(" IDC ")`? · "; entry = ""; n = 0 }
    /^[[:space:]]*```/ { fence = !fence; next }
    fence { next }
    $0 ~ H { flush(); match($0, IDC); entry = substr($0, RSTART, RLENGTH); etier = ""; edet = ""; inblock = 0; next }
    entry == "" { next }
    /^\*\*Enforcement:\*\* tier [123]/ { t = $0; sub(/^\*\*Enforcement:\*\* tier /, "", t); etier = substr(t, 1, 1)
                                        edet = (index(t, " — ") ? substr(t, index(t, " — ") + length(" — ")) : ""); next }
    /^\*\*Carries\.\*\*[[:space:]]*$/ { inblock = 1; next }
    !inblock { next }
    /^[[:space:]]*$/ { next }
    !/^- / { inblock = 0; next }
    {
      n++; P_ln[n] = NR; P_tier[n] = ""; P_det[n] = ""; P_rule[n] = ""
      line = $0
      if (!match(line, PRE)) { P_id[n] = ""; P_kind[n] = "bad"; P_val[n] = substr(line, 1, 90); next }
      pre = substr(line, 1, RLENGTH); rest = substr(line, RLENGTH + 1)
      match(pre, IDC); id = substr(pre, RSTART, RLENGTH)
      # separators measured with length(): the middle dot and the em dash are several bytes in a
      # byte-counting awk and one character in another, and an offset must be right in both
      SB = " · binds: "; SS = " · settled: "; ST = " · tier "; SD = " — "
      bi = index(rest, SB); si = index(rest, SS)
      if (bi == 0 && si == 0) { P_id[n] = id; P_kind[n] = "bad"; P_val[n] = substr(line, 1, 90); next }
      if (bi > 0 && (si == 0 || bi < si)) { kind = "binds"; rule = substr(rest, 1, bi - 1); tail = substr(rest, bi + length(SB)) }
      else { kind = "settled"; rule = substr(rest, 1, si - 1); tail = substr(rest, si + length(SS)) }
      val = tail
      if (match(tail, / · tier [123]/)) {
        val = substr(tail, 1, RSTART - 1); after = substr(tail, RSTART + length(ST))
        P_tier[n] = substr(after, 1, 1)
        if (index(after, SD)) P_det[n] = substr(after, index(after, SD) + length(SD))
      }
      P_id[n] = id; P_kind[n] = kind; P_val[n] = val; P_rule[n] = rule
    }
    END { flush() }
  ' "$1"
}
lines_of() {   # $1 = folder -> the parsed lines of both logs, read where the folder is read (src_of)
  local lg s; s=$(src_of "$1")
  for lg in DECISIONS.md LESSONS-LEARNED.md; do [ -f "$s/$lg" ] && parse_lines "$s/$lg" "$1/$lg"; done
}
entries_of() {   # $1 = log -> the ids of its live entries, in order (a heading carrying ROTATED is a
                 # pointer in the wrong shape, not an entry; the carrier check reads the same heads)
  awk -v IDC="$id_core" '/^[[:space:]]*```/ { fence = !fence; next } fence { next }
    $0 ~ "^#{1,4}[[:space:]]*`?(" IDC ")" && !/ROTATED/ { match($0, IDC); print substr($0, RSTART, RLENGTH) }' "$1"
}
carried_of() {   # $1 = folder, $2 = the parsed lines (a file) -> per log: carried <TAB> total <TAB> the uncarried ids
  local lg s; s=$(src_of "$1")
  for lg in DECISIONS.md LESSONS-LEARNED.md; do
    [ -f "$s/$lg" ] || continue
    awk -F'\t' -v f="$1/$lg" '
      FILENAME == ARGV[1] { if ($1 == f && $3 == $4 && ($5 == "binds" || $5 == "settled")) c[$3] = 1; next }
      { t++; if ($0 in c) k++; else u = u ", `" $0 "`" }
      END { printf "%s\t%d\t%d\t%s\n", f, k, t, substr(u, 3) }' "$2" <(entries_of "$s/$lg")
  done
}

# gen_index FOLDER [PREFIX] — the index (no prefix) or the lane view of PREFIX, to stdout
gen_index() {
  local d="$1" prefix="${2:-}" agent rules n lanes all carried k_all t_all
  agent=$(printf '%s' "$d" | sed -nE 's#^\.critos/memory/a([0-9]+)$#\1#p')
  all=$(mktemp); lines_of "$d" > "$all"
  rules=$(awk -F'\t' '$5 == "binds"' "$all")
  u=$(printf '%s\n' "$rules" | awk -F'\t' '$7 == "?"' | grep -c '.')
  carried=$(carried_of "$d" "$all"); rm -f "$all"
  k_all=$(printf '%s\n' "$carried" | awk -F'\t' '{ k += $2 } END { print k + 0 }')
  t_all=$(printf '%s\n' "$carried" | awk -F'\t' '{ t += $3 } END { print t + 0 }')
  if [ -n "$prefix" ]; then
    rules=$(printf '%s\n' "$rules" | awk -F'\t' -v p="$prefix" '$6 == p || index($6, p "/") == 1')
  fi
  n=$(printf '%s\n' "$rules" | grep -c '.')
  lanes=$(printf '%s\n' "$rules" | cut -f6 | grep '.' | sort -u)
  if [ -n "$prefix" ]; then
    echo "# IN-FORCE · $prefix — the law in force of AGENT ${agent:-?}, one lane (generated)"
  else
    echo "# IN-FORCE — the law in force of AGENT ${agent:-?} (generated)"
  fi
  echo
  echo "> ⚠️ **GENERATED — do not hand-edit.** Regenerate with"
  echo "> \`bash ~/.claude/skills/crit-in-force/in-force.sh\`. One line per rule in force, read from the"
  echo "> \`Carries\` blocks of the live entries of this folder's logs; a settled rule is not here — it"
  echo "> resolves through the atlas. The boot reads this file; a log is opened at the id it names."
  echo "> Cite the entry, never this file."
  echo
  echo "**Generated:** $stamp (UTC) · **Folder:** \`$d/\` · **Rules in force:** $n · **Lanes:** $(printf '%s\n' "$lanes" | grep -c '.')"
  if [ -z "$prefix" ]; then
    # the head counts what was read and names what it cannot summarise: the boot opens those whole
    echo "**Carried:** $k_all of $t_all live entries"
    printf '%s\n' "$carried" | awk -F'\t' '$4 != "" { n = $1; sub(/.*\//, "", n); print "**Uncarried:** " $4 " — in `" n "`: opened whole until each carries its rule" }'
    # the untiered beside the uncarried: a rule in force declares its tier, and the debt is read here
    [ "$u" -gt 0 ] && echo "**Untiered:** $u of $n rule lines — tier ? until the line, or its entry's Enforcement: field, declares one"
    [ "$n" = 0 ] && [ "$k_all" = "$t_all" ] && { echo; echo "(no rule in force — $k_all of $t_all live entries carry their rule, none binds)"; }
  fi
  while IFS= read -r lane; do
    [ -n "$lane" ] || continue
    echo
    if [ -n "$prefix" ]; then
      sub=${lane#"$prefix"}; sub=${sub#/}; [ -n "$sub" ] || sub="$prefix"
      echo "## $sub"
    else
      echo "## $lane"
    fi
    echo
    printf '%s\n' "$rules" | awk -F'\t' -v l="$lane" '$6 == l {
      line = "- `" $4 "` · " $9 " · tier " $7
      if ($8 != "") line = line " — " $8
      print line }'
  done <<< "$lanes"
}

# views_of FOLDER — the lane prefixes whose view sits beside the index
views_of() { ls -1 "$(src_of "$1")"/IN-FORCE.*.md 2>/dev/null | sed -E 's#.*/IN-FORCE\.(.*)\.md$#\1#'; }
write_index() {   # $1 = folder, $2 = lane prefix or "" — written only when the content differs (the stamp line excepted)
  local d="$1" p="$2" f tmp
  f="$d/IN-FORCE.md"; [ -n "$p" ] && f="$d/IN-FORCE.$p.md"
  tmp=$(mktemp); gen_index "$d" $p > "$tmp"
  if [ -f "$f" ] && diff -q <(grep -v '^\*\*Generated:\*\*' "$f") <(grep -v '^\*\*Generated:\*\*' "$tmp") >/dev/null 2>&1; then
    rm -f "$tmp"; echo "unchanged $f ($(grep -c '' "$f") lines)"
  else
    mv "$tmp" "$f"; echo "wrote $f ($(grep -c '' "$f") lines)"; wrote=1
  fi
}

case "$mode" in
  lines)
    for d in "${folders[@]}"; do lines_of "$d"; done
    exit 0 ;;
  write)
    [ "${#folders[@]}" = 0 ] && { echo "(no memory folder with a log in this repo — nothing to generate)"; exit 0; }
    wrote=0; skipped=0
    for d in "${folders[@]}"; do
      [ -d "$d" ] || continue
      is_owned "$d" || { skipped=$((skipped + 1)); continue; }
      write_index "$d" ""
      for p in ${lanes[@]+"${lanes[@]}"} $(views_of "$d"); do
        [ -n "$p" ] || continue
        write_index "$d" "$p"
      done
    done
    [ "$wrote" = 0 ] && [ "$skipped" -gt 0 ] && echo "(no folder owned: nothing written — name yours with --own a<N>; every other folder is read as committed and never written)"
    exit 0 ;;
  check)
    rc=0
    [ "${#folders[@]}" = 0 ] && { echo "(no memory folder with a log in this repo — nothing to check)"; exit 0; }
    for d in "${folders[@]}"; do
      if is_owned "$d"; then
        [ -d "$d" ] || continue
      elif [ "$head_ok" = 1 ] && [ -z "$(git ls-tree -r --name-only HEAD -- "$d" 2>/dev/null | head -1)" ]; then
        echo "(skip  $d/ — nothing at HEAD: read as empty; its owner's index is checked at its own round)"; continue
      fi
      for p in "" $(views_of "$d"); do
        f="$d/IN-FORCE.md"; [ -n "$p" ] && f="$d/IN-FORCE.$p.md"
        fresh=$(gen_index "$d" $p)
        nl=$(printf '%s\n' "$fresh" | grep -c '')
        # an owned folder's index is the file in the tree; another's is the committed one
        if is_owned "$d" || [ "$head_ok" = 0 ]; then
          where=""; have=0; [ -f "$f" ] && { have=1; cur=$(cat "$f"); }
        else
          where=" (as committed)"; have=0; git cat-file -e "HEAD:$f" 2>/dev/null && { have=1; cur=$(git show "HEAD:$f" 2>/dev/null); }
        fi
        if [ "$have" = 0 ]; then
          echo "STALE  $f —$where missing: the boot reads it and finds nothing (regenerate: bash ~/.claude/skills/crit-in-force/in-force.sh --own a<N>)"; rc=1
        elif ! diff -q <(printf '%s\n' "$cur" | grep -v '^\*\*Generated:\*\*') <(printf '%s\n' "$fresh" | grep -v '^\*\*Generated:\*\*') >/dev/null 2>&1; then
          echo "STALE  $f —$where differs from a fresh generation: a rule moved, appeared or vanished (regenerate: bash ~/.claude/skills/crit-in-force/in-force.sh --own a<N>)"; rc=1
        else
          echo "FRESH  $f ($nl lines$where)"
        fi
        [ "$nl" -gt "$budget" ] && echo "BUDGET  $f — $nl lines of $budget: the law in force of one agent should be read at every boot; consolidate (contract-memory § 2)"
      done
    done
    exit $rc ;;
esac
