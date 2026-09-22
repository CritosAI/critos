#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# memory-index — generate MEMORY-INDEX.md: the deterministic atlas of a project's memory.
#
# The atlas holds no facts, only ADDRESSES: every line is `<id> -> <file>:<line>`, harvested
# from the files themselves, so it cannot drift into a second source of truth. It is disposable
# by design: delete it and regenerate. Never hand-edit it, never cite it (cite what it points at).
#
# Usage:  bash ~/.claude/skills/crit-memory-index/memory-index.sh [--check]
#           (no args) rewrite MEMORY-INDEX.md at the repo root
#           --check   compare the file on disk with a fresh generation. The verdict is split:
#                       exit 1 = STALE-ID     an id moved, appeared or vanished — the atlas may
#                                             send a reader to a DIFFERENT entry. Regenerate now.
#                       exit 2 = STALE-COUNT  only counts or cells moved; every id still
#                                             resolves. Regenerate at the round-close.
#                       exit 0 = up to date.
set -uo pipefail
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "memory-index: not inside a git repository. If Claude Code was opened ABOVE the repo, none of the repo's .claude/ (steward, hooks) is loaded - reopen it at the repo root." >&2; exit 1; }
cd "$root" || exit 1
mode="${1:-}"
out="MEMORY-INDEX.md"
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
    st="—"; de="—"; le="—"
    # `grep -c` prints 0 AND exits 1 on no match: swallow the status, never append a fallback.
    [ -f "$d/STATUS.md" ] && st="$(grep -c '' "$d/STATUS.md") ln"
    [ -f "$d/DECISIONS.md" ] && de="$( { grep -cE '^#{1,4}[[:space:]]*(ADR|D)-' "$d/DECISIONS.md" || true; } 2>/dev/null) ADR"
    if [ -f "$d/LESSONS-LEARNED.md" ]; then
      lc=$( { grep -cE '^#{1,4}[[:space:]]*L-' "$d/LESSONS-LEARNED.md" || true; } 2>/dev/null)
      if [ "$lc" -gt 0 ]; then le="$lc lessons"
      else le="$(grep -c '' "$d/LESSONS-LEARNED.md") ln · **no L- ids**"   # a non-empty log with no ids is not "0 lessons"
      fi
    fi
    other=$(ls -1 "$d" 2>/dev/null | grep -vE '^(STATUS|DECISIONS|LESSONS-LEARNED|README)\.md$' | paste -sd' ' - | cut -c1-60)
    printf '| [`%s`](%s) | %s | %s | %s | %s | %s |\n' "$d" "$d" "$(owner_of "$d")" "$st" "$de" "$le" "${other:-—}"
  done < <(tracked_and_new '.critos/memory/*/*.md' | sed -E 's#/[^/]+$##' | sort -u)

  echo
  echo "## Decisions — every ADR, by ID"
  echo
  echo "Cite an ADR **by ID**, never by path (the ID is stable; paths move)."
  echo
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    n=$( { grep -cE '^#{1,4}[[:space:]]*(ADR|D)-' "$f" || true; } 2>/dev/null)
    [ "$n" = 0 ] && continue
    echo "### \`$f\` — $n"
    echo
    grep -nE '^#{1,4}[[:space:]]*(ADR|D)-' "$f" \
      | sed -E 's/^([0-9]+):#+[[:space:]]*/- L\1 · /' \
      | sed -E 's/[[:space:]]+$//' | cut -c1-160
    echo
  done < <(tracked_and_new '*DECISIONS*.md')

  echo "## Lessons — every lesson, by ID"
  echo
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    n=$( { grep -cE '^#{1,4}[[:space:]]*L-' "$f" || true; } 2>/dev/null)
    [ "$n" = 0 ] && continue
    echo "### \`$f\` — $n"
    echo
    grep -nE '^#{1,4}[[:space:]]*L-' "$f" \
      | sed -E 's/^([0-9]+):#+[[:space:]]*/- L\1 · /' \
      | sed -E 's/[[:space:]]+$//' | cut -c1-160
    echo
  done < <(tracked_and_new '*LESSONS*.md')

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

mv "$tmp" "$out"
echo "wrote $out ($(grep -c '' "$out") lines)"
