#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# memory-index — generate MEMORY-INDEX.md: the deterministic atlas of a project's memory.
#
# The atlas holds no facts, only ADDRESSES: every line is `<id> -> <file>:<line>`, harvested
# from the files themselves, so it cannot drift into a second source of truth. It is disposable
# by design: delete it and regenerate. Never hand-edit it, never cite it (cite what it points at).
#
# Usage:  bash ~/.claude/skills/crit-memory-index/memory-index.sh [--check] [--own a<N>]...
#           (no args) rewrite MEMORY-INDEX.md at the repo root — only when its content changed
#           --own a<N>  the runner's folder (repeatable): read from the working tree; every other
#                       memory folder is read as committed (HEAD), so the atlas never carries a
#                       neighbour's uncommitted state. Without it, every folder is read at HEAD.
#           --check   compare the file on disk with a fresh generation. The verdict is split:
#                       exit 1 = STALE-ID     an id moved, appeared or vanished — the atlas may
#                                             send a reader to a DIFFERENT entry. Regenerate now.
#                       exit 2 = STALE-COUNT  only counts or cells moved; every id still
#                                             resolves. Regenerate at the round-close.
#                       exit 0 = up to date.
set -uo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "memory-index: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1
mode=""; own=(); folders=()
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode="--check"; shift ;;
    --own) own+=("$2"); shift 2 ;;
    --me) own+=("a$2"); shift 2 ;;    # the controls' shared convention: --me <N> is --own a<N>
    --domain) shift 2 ;;
    *) echo "memory-index: unknown argument $1" >&2; exit 2 ;;
  esac
done
out="MEMORY-INDEX.md"

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
is_owned() { local x; for x in ${owned[@]+"${owned[@]}"}; do [ "$x" = "$1" ] && return 0; done; return 1; }
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

src_file() {   # $1 = a file -> the path it is read from: its HEAD copy when it lies in an unowned memory folder
  local d; d=$(printf '%s' "$1" | sed -nE 's#^(\.critos/memory/a[0-9]+)/.*$#\1#p')
  if [ -n "$d" ] && [ "$head_ok" = 1 ] && ! is_owned "$d"; then printf '%s/%s' "$(src_of "$d")" "${1#$d/}"; else printf '%s' "$1"; fi
}
in_unowned() { local d; d=$(printf '%s' "$1" | sed -nE 's#^(\.critos/memory/a[0-9]+)/.*$#\1#p'); [ -n "$d" ] && [ "$head_ok" = 1 ] && ! is_owned "$d"; }
log_files() {   # every *<KIND>*.md: tracked and new outside the unowned memory folders, as committed inside them
  { tracked_and_new "*$1*.md" | while IFS= read -r f; do in_unowned "$f" || printf '%s\n' "$f"; done
    [ "$head_ok" = 1 ] && git ls-tree -r --name-only HEAD -- '.critos/memory/' 2>/dev/null | grep -E "^\.critos/memory/a[0-9]+/.*$1.*\.md$" | while IFS= read -r f; do in_unowned "$f" && printf '%s\n' "$f"; done; } | sort -u
}
# the HEAD copies of every memory folder not owned, made once, before anything reads them
if [ "$head_ok" = 1 ]; then
  while IFS= read -r d; do [ -n "$d" ] && ! is_owned "$d" && materialize "$d"; done < <(git ls-tree -d --name-only HEAD -- '.critos/memory/' 2>/dev/null)
fi
memory_folders() {   # the folders of the table: owned ones from the tree, the others as committed
  { for o in ${owned[@]+"${owned[@]}"}; do tracked_and_new "$o/*.md"; done
    if [ "$head_ok" = 1 ]; then
      git ls-tree -r --name-only HEAD -- '.critos/memory/' 2>/dev/null | grep -E '^\.critos/memory/[^/]+/[^/]+\.md$' | while IFS= read -r f; do d=${f%/*}; is_owned "$d" || printf '%s\n' "$f"; done
    else tracked_and_new '.critos/memory/*/*.md'; fi; } | sed -E 's#/[^/]+$##' | grep -E '^\.critos/memory/[^/]+$' | sort -u
}
tmp=$(mktemp)

# Tracked AND new files: a rotation creates archive files, and until they are staged a
# tracked-only pass would make the atlas silently smaller at exactly that moment.
tracked_and_new() { { git ls-files "$@"; git ls-files --others --exclude-standard -- "$@"; } | sort -u; }

# The writer of a memory folder is encoded in its path (`.critos/memory/a<N>/…`): structural
# inference cannot be wrong. Anything else gets an honest gap, never a guessed owner.
owner_of() {
  local hit
  hit=$(printf '%s' "$1" | sed -nE 's#^\.critos/memory/a([0-9]+)(/.*)?$#A\1#p')
  printf '%s' "${hit:-(unmapped)}"
}

{
  echo "# MEMORY-INDEX — generated atlas of this project's memory"
  echo
  echo "> ⚠️ **GENERATED — do not hand-edit.** Regenerate with"
  echo "> \`bash ~/.claude/skills/crit-memory-index/memory-index.sh\`. This file holds **no facts, only"
  echo "> addresses**: every line points at the artifact that owns the fact. Cite what it points"
  echo "> at, never this file. If it disagrees with a source, the source wins and this is stale."
  echo
  echo "**Generated:** $(date -u +%Y-%m-%d) (UTC) · **Repo:** \`$(basename "$root")\`"
  echo
  echo "## Memory folders (one writer each)"
  echo
  echo "| Folder | Writer | STATUS | DECISIONS | LESSONS-LEARNED | Other |"
  echo "|---|---|---|---|---|---|"
  while IFS= read -r d; do
    [ -z "$d" ] && continue
    st="—"; de="—"; le="—"; s=$(src_of "$d")
    # `grep -c` prints 0 AND exits 1 on no match: swallow the status, never append a fallback.
    [ -f "$s/STATUS.md" ] && st="$(grep -c '' "$s/STATUS.md") ln"
    [ -f "$s/DECISIONS.md" ] && de="$( { grep -E '^#{1,4}[[:space:]]*(ADR|D)-' "$s/DECISIONS.md" | grep -vc ROTATED || true; } 2>/dev/null) ADR"
    if [ -f "$s/LESSONS-LEARNED.md" ]; then
      lc=$( { grep -E '^#{1,4}[[:space:]]*L-' "$s/LESSONS-LEARNED.md" | grep -vc ROTATED || true; } 2>/dev/null)
      if [ "$lc" -gt 0 ]; then le="$lc lessons"
      else le="$(grep -c '' "$s/LESSONS-LEARNED.md") ln · **no L- ids**"   # a non-empty log with no ids is not "0 lessons"
      fi
    fi
    other=$(ls -1 "$s" 2>/dev/null | grep -vE '^(STATUS|DECISIONS|LESSONS-LEARNED|README)\.md$' | paste -sd' ' - | cut -c1-60)
    printf '| [`%s`](%s) | %s | %s | %s | %s | %s |\n' "$d" "$d" "$(owner_of "$d")" "$st" "$de" "$le" "${other:-—}"
  done < <(memory_folders)

  echo
  echo "## Decisions — every ADR, by ID"
  echo
  echo "Cite an ADR **by ID**, never by path (the ID is stable; paths move)."
  # A heading that carries ROTATED is a stub of the old pointer form, never an entry: neither
  # listed nor counted (contract-memory § 2). A title is copied as TEXT: a markdown link inside a heading is
  # de-linked, because a relative link copied one folder up breaks, and the atlas is generated —
  # nobody may hand-fix it. The atlas holds addresses by LINE, never links inside titles.
  echo
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    sf=$(src_file "$f")
    n=$( { grep -E '^#{1,4}[[:space:]]*(ADR|D)-' "$sf" | grep -vc ROTATED || true; } 2>/dev/null)
    [ "$n" = 0 ] && continue
    echo "### \`$f\` — $n"
    echo
    grep -nE '^#{1,4}[[:space:]]*(ADR|D)-' "$sf" | grep -v ROTATED \
      | sed -E 's/^([0-9]+):#+[[:space:]]*/- L\1 · /' \
      | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g' \
      | sed -E 's/[[:space:]]+$//' | cut -c1-160
    echo
  done < <(log_files DECISIONS)

  echo "## Lessons — every lesson, by ID"
  echo
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    sf=$(src_file "$f")
    n=$( { grep -E '^#{1,4}[[:space:]]*L-' "$sf" | grep -vc ROTATED || true; } 2>/dev/null)
    [ "$n" = 0 ] && continue
    echo "### \`$f\` — $n"
    echo
    grep -nE '^#{1,4}[[:space:]]*L-' "$sf" | grep -v ROTATED \
      | sed -E 's/^([0-9]+):#+[[:space:]]*/- L\1 · /' \
      | sed -E 's/\[([^]]*)\]\([^)]*\)/\1/g' \
      | sed -E 's/[[:space:]]+$//' | cut -c1-160
    echo
  done < <(log_files LESSONS)

  echo "## Registers"
  echo
  # A pointer and the command that answers the question — never a count: a count is a fact, and
  # "how many are live" belongs to the one inbox classifier, not to a copy of it.
  for r in .critos/shared/HANDOFFS.md .critos/shared/ROADMAP.md .critos/shared/CONTRACTS.md; do
    [ -f "$r" ] || continue
    case "$r" in
      *HANDOFFS*)
        printf -- '- [`%s`](%s) — the inbox. **The authority on what is OWED** (a STATUS may not assert it).\n' "$r" "$r"
        printf -- '  How many are live / owed by you: `bash ~/.claude/skills/crit-status-check/status-check.sh --me <N>`\n' ;;
      *ROADMAP*)
        printf -- '- [`%s`](%s) — the roadmap: shared / cross-domain efforts only. Rows you LEAD are printed by the same command.\n' "$r" "$r" ;;
      *CONTRACTS*)
        printf -- '- [`%s`](%s) — the contract register. *A map that links; never a copy.*\n' "$r" "$r" ;;
    esac
  done
  echo
  echo "## The method"
  echo
  if [ -f .critos/system/contract-system.md ]; then
    echo 'The contracts: `.critos/system/` — dispatch table (**where do I write this?**) →'
    echo '`contract-system § 3`. The rationale guides live in the CritOS repository (`docs/`), read on demand.'
  elif [ -f system/contract-system.md ] && [ -f releases.manifest ]; then
    echo 'This repo is CritOS itself: contracts at `system/` (dispatch: `contract-system § 3`),'
    echo 'guides at `docs/`.'
  else
    echo '(no system tier found in this repo)'
  fi
} > "$tmp"

if [ "$mode" = "--check" ]; then
  if [ -f "$out" ] && diff -q <(grep -v '^\*\*Generated:\*\*' "$out") <(grep -v '^\*\*Generated:\*\*' "$tmp") >/dev/null 2>&1; then
    echo "MEMORY-INDEX up to date."
    rm -f "$tmp"; exit 0
  fi
  # The ID set = every `### <file> — n` header (count stripped) + every `- L<n> · …` pointer
  # line. A missing atlas has an empty ID set and lands in STALE-ID, which is right.
  ids() { grep -E '^### |^- L[0-9]+ · ' "$1" 2>/dev/null | sed -E 's/^(### .*) — [0-9]+$/\1/'; }
  if diff -q <(ids "$out") <(ids "$tmp") >/dev/null 2>&1; then
    echo "MEMORY-INDEX is STALE-COUNT (bookkeeping): only counts/cells moved; every id still resolves where the atlas says."
    echo "  Regenerate at the round-close: bash ~/.claude/skills/crit-memory-index/memory-index.sh"
    rm -f "$tmp"; exit 2
  fi
  echo "MEMORY-INDEX is STALE-ID (danger): an id moved, appeared or vanished — the atlas may send a reader to a DIFFERENT entry."
  echo "  Regenerate NOW, this round: bash ~/.claude/skills/crit-memory-index/memory-index.sh"
  rm -f "$tmp"; exit 1
fi

# written only when the content changed (the stamp line excepted): the stamp says when the
# atlas last changed, not when someone last looked, and a neighbour's round never dirties it
if [ -f "$out" ] && diff -q <(grep -v '^\*\*Generated:\*\*' "$out") <(grep -v '^\*\*Generated:\*\*' "$tmp") >/dev/null 2>&1; then
  rm -f "$tmp"; echo "MEMORY-INDEX unchanged ($(grep -c '' "$out") lines)"; exit 0
fi
mv "$tmp" "$out"
echo "wrote $out ($(grep -c '' "$out") lines)"
