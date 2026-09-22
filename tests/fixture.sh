#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# Builds a throwaway git repo in which EVERY check of the crit-doc-lint battery has a known
# positive. A detector's zero is evidence only after the detector was seen firing: this is where
# each one is seen firing. Used by tests/run.sh; safe to run by hand.
#
# Usage:  bash tests/fixture.sh <target-dir> <pin-source-dir>
#           pin-source-dir  the folder holding the 8 tier files to pin — normally ../system
#                           (one of them gets a local edit, so that [14] has its positive)
set -euo pipefail
T="$1"; PIN="$2"; L=".critos"
rm -rf "$T"; mkdir -p "$T"; cd "$T"; git init -q .
mkdir -p "$L/system" "$L/project/agents" "$L/memory/a2" "$L/memory/a3" "$L/memory/a9" "$L/memory/notes" \
         "$L/shared/archive" docs/shelf src

# [14] a pinned tier with one edited file
for f in contract-system.md contract-agent.md contract-session.md contract-memory.md contract-shared.md VERSION CHANGELOG.md README.md; do
  cp "$PIN/$f" "$L/system/$f"
done
printf '\nlocal edit\n' >> "$L/system/contract-shared.md"
# [14] VERSION-SPLIT: a declared satellite whose pinned tier declares another release than the hub
mkdir -p .claude sat/$L/system
printf 'sat   # a satellite left behind by a migration\n' > .claude/repos
printf '{ "system": "0.0.1" }\n' > "sat/$L/system/VERSION"

# [1] BROKEN  [3] ORPHAN  [16] RETIRED-REF
cat > README.md <<EOF
# fixture
[missing](docs/missing.md) · [retired](docs/old.md) · [roster]($L/project/agents.md) · [shelf](docs/shelf/README.md)
EOF
printf '# ⚰ RETIRED — moved\n' > docs/old.md
printf '# orphan\nnobody links here\n' > docs/orphan.md

# [21] CITED-ID: one lost id (flagged) beside three that must resolve — a live entry, an
# archived entry, a retired id kept alive by the alias table in a log's head
printf '\nDecided in ADR-A2-001, earlier in ADR-A2-000, once known as ADR-OLD-005, and ADR-LEG-042 of a retired sequence; lost: ADR-A2-777; lost too, in the LIVE sequence an alias line points at: ADR-A3-888.\n' >> README.md
mkdir -p "$L/memory/a2/archive"
printf '# archive\n## ADR-A2-000 — archived and still resolving\nit cites ADR-A2-888, which is history, not a live citation\n' > "$L/memory/a2/archive/DECISIONS-archive-2026-08.md"

# [2] PATH-IN-CODE
printf '// see doc/guide-something.md for the rule\nexport const x = 1;\n' > src/x.js

# [4] DANGLING-SKILL (CLAUDE.md is in the skill layer's scan scope)
printf '# routing\nRun `/no-such-skill` first.\n' > CLAUDE.md

# [20] SHELF-INDEX: unlisted doc (A2) · address that does not resolve (A3) · prose address (A4)
printf '# shelf\n- [a](a.md)\n' > docs/shelf/README.md
printf '# a\n' > docs/shelf/a.md; printf '# b — never listed\n' > docs/shelf/b.md
cat > "$L/project/agents.md" <<EOF
# roster
## Actors
| # | Role (one line) | Form | Domain | Memory | Shelf | Definition |
|---|---|---|---|---|---|---|
| A1 | Steward | native | governance | \`$L/memory/a1/\` | — | system |
| A2 | Builder | session | code | \`$L/memory/a2/\` | [shelf](../../docs/shelf/README.md) | [def](agents/agent-2.md) |
| A3 | Tester | session | tests | \`$L/memory/a3/\` | [gone](../../docs/nowhere/README.md) | — |
| A4 | Writer | session | docs | \`$L/memory/a4/\` | the docs folder, somewhere | — |
EOF

# [15] DEFINITION-PATH  [18] DEFINITION-SHAPE  [19] DEFINITION-ACTOR
cat > "$L/project/agents/agent-2.md" <<EOF
# AGENT 2
## 1 · Purpose
build
## 2 · Domain
the code; its map lives in docs/maps/code-map.md
## 3 · What I do NOT do
- I do not test: that is A3's.
## 9 · Close-out
never a template section
EOF

# [8] STATUS-CHRONICLE (over the line budget)   [9] STALE-STATUS (the old commit date below)
{ echo "# status"; for i in $(seq 1 215); do echo "line $i"; done; } > "$L/memory/a2/STATUS.md"

# [11] TIER-3-LESSON   [10] DANGLING-WIKI-LINK
cat > "$L/memory/a2/LESSONS-LEARNED.md" <<EOF
# lessons
## L-A2-001 — 2026-09-01 — accepted_rule — always check twice
no enforcement field here; see [[no-such-slug]]
EOF

# [12] UNROTATED-LOG + ARCHIVABLE (a2)  ·  DECLARED-OVER (a3)
{ echo "# decisions"; echo "## ADR-A2-001 — first"; echo "**Status:** superseded by ADR-A2-002"; echo "## ADR-A2-002 — second"; for i in $(seq 1 1210); do echo "l$i"; done; } > "$L/memory/a2/DECISIONS.md"
{ echo "# decisions"; echo "> DECLARED EXEMPTION — ACTIVE: every entry here is cited"; echo "> alias: ADR-OLD-005 -> ADR-A3-001"; echo "> a retired sequence: ADR-LEG-NNN -> ADR-A3-NNN"; for i in $(seq 1 1210); do echo "l$i"; done; } > "$L/memory/a3/DECISIONS.md"

# status-check axis 1: a dated STATUS beside a DECISIONS log (a3)
printf '# status
**Last updated:** 2026-07-01
' > "$L/memory/a3/STATUS.md"

# [13] MEMORY-SHAPE: a folder that is not a<N> (notes/) and an unrostered a<N> (a9/)
echo x > "$L/memory/notes/x.md"; echo x > "$L/memory/a9/STATUS.md"

# [5] PING-PONG · NO-DONE-WHEN · MULTI-OWNER   [7] BAD-TOKEN · UNBOLDED-TOKEN
cat > "$L/shared/HANDOFFS.md" <<'EOF'
# inbox
- 2026-09-10 — AGENT 2 → AGENT 3: **[OPEN — the schema needs a column]** please add it [src/schema.sql]
- 2026-09-09 — AGENT 3 → AGENT 2: **[CLOSED — not mine, back to you]** [src/schema.sql]
- 2026-09-08 — AGENT 2 → AGENT 3: **[CLOSED — yours, I think]** [src/schema.sql]
- 2026-09-07 — AGENT 3 → AGENT 2: **[CLOSED — first ask]** [src/schema.sql]
- 2026-09-06 — AGENT 2 → AGENT 3, AGENT 4: **[OPEN — both of you look at this. Done when: one of you answers]** [src/other.js]
- 2026-09-05 — AGENT 2 → AGENT 3: **[URGENT NOW — an invented token]** do this now [src/a.js]
- 2026-09-04 — AGENT 2 → AGENT 3: [OPEN — not bolded. Done when: bolded] [src/b.js]
- 2026-09-03 — AGENT 10 → AGENT 1: **[OPEN — a two-digit agent volleys. Done when: decided]** [src/volley.js]
- 2026-09-02 — AGENT 1 → AGENT 10: **[CLOSED — back to you]** [src/volley.js]
- 2026-09-01 — AGENT 10 → AGENT 1: **[CLOSED — first ask]** [src/volley.js]
EOF
# [17] COLD-LIVE-TOKEN
printf '# archive\nEvery `[OPEN]` entry stayed in the live inbox; this line only QUOTES the grammar.\n- 2026-08-01 — AGENT 2 → AGENT 3: **[OPEN — buried alive. Done when: found]** [src/c.js]\n- 2026-08-02 — AGENT 4 → AGENT 5: **[ABSORBED 2026-08-03 by A5 — it was `[OPEN]` for a day]** [src/quoted-1.js]\n- 2026-08-03 — AGENT 6 → AGENT 7: **ACK — my sweep is done: my 5 `[OPEN]`s are closed** [src/quoted-2.js]\n' > "$L/shared/archive/HANDOFFS-archive-2026-08.md"

# [6] STALE-Rx (an open row; the commit below is dated in the past)
cat > "$L/shared/ROADMAP.md" <<EOF
# roadmap
| # | Effort | Lead | Status |
|---|---|---|---|
| R1 | a thing nobody touched | A2 | 🟡 open |
| R2 | a settled thing | A2 | ✅ done 2026-08-01 |
EOF
printf '# contracts\n' > "$L/shared/CONTRACTS.md"

git add -A . >/dev/null 2>&1
GIT_AUTHOR_DATE="2026-08-01T00:00:00Z" GIT_COMMITTER_DATE="2026-08-01T00:00:00Z" \
  git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "fixture" >/dev/null
echo "fixture built: $T"
