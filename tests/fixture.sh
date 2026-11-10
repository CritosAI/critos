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
# [1] TRACKED-MISSING: a tracked path deleted from the disk after the commit (at the end), never
#     from the index — an uncommitted deletion; read by no check, so not an ORPHAN
printf '# gone\n' > docs/gone.md

# [21] CITED-ID: one lost id (flagged) beside three that must resolve — a live entry, an
# archived entry, a retired id kept alive by the alias table in a log's head
printf '\nDecided in ADR-A2-001, earlier in ADR-A2-000, once known as ADR-OLD-005, and ADR-LEG-042 of a retired sequence; lost: ADR-A2-777; lost too, in the LIVE sequence an alias line points at: ADR-A3-888.\n' >> README.md
mkdir -p "$L/memory/a2/archive"
# [26] UNCARRIED, a second positive: an entry whose TITLE says the log rotated — a title, not a stub of
#      the pointer form (`— ROTATED YYYY-MM-DD to`): every archive reader reads it as the entry it is,
#      and nothing live carries it. And a heading of the Q- family, read only through id-families.
printf '# archive\n## ADR-A2-000 — archived and still resolving\nit cites ADR-A2-888, which is history, not a live citation\n## D-007 — a decision of the scheme before the method\n## D-008 — another of the scheme, carried by nothing\n## D-008 — ADDENDUM 2 — a second heading under one id (HEADED-TWICE)\n## ADR-A2-006 — the round the log ROTATED, this entry stayed: a title, not a stub\n## Q-0001 — a decision of a third scheme, read through the families only\n' > "$L/memory/a2/archive/DECISIONS-archive-2026-08.md"
# a declared id family: `D-NNN` is grammar, so D-007 (headed above) resolves and D-099 is lost;
# its home is declared (a2), so D-009 headed in a3's archive is TWO-HOMES from the first heading;
# the Z- family's declared home names no memory folder (a second TWO-HOMES, on the line); the
# Q- family is headed in a2's archive and carried by a pointer — the atlas lists it by the grammar
printf '# ids of the scheme before the method\n^D-[0-9]{3}$ · home: a2\n^Z-[0-9]{3}$ · home: a7\n^Q-[0-9]{4}$ · home: a2\n' > "$L/project/id-families"
printf 'Under the old scheme: D-007 holds, D-099 was never written.\n' >> README.md

# [2] PATH-IN-CODE
printf '// see doc/guide-something.md for the rule\nexport const x = 1;\n' > src/x.js

# [4] DANGLING-SKILL (CLAUDE.md is in the skill layer's scan scope)
printf '# routing\nRun `/no-such-skill` first.\n' > CLAUDE.md

# [20] SHELF-INDEX: unlisted doc (A2) · address that does not resolve (A3) · prose address (A4)
# [22] ROOTS: a root matching nothing (A2, DANGLING) · one root under two actors (A3 + A4,
#      OVERLAP) · tracked files under no root and no ruled surface (UNROOTED: README.md at the
#      root, sat/, the notes/ folder under memory) — covered, and must stay covered: a ruled
#      surface (src/schema.sql); a ruled surface whose Owner cell names the actor in PROSE
#      (shared/jobs.yml — "applied by A3"); a shelf with no Roots cell (A5's guides/ — the shelf
#      is a root by construction)
printf '# shelf\n- [a](a.md)\n' > docs/shelf/README.md
printf '# a\n' > docs/shelf/a.md; printf '# b — never listed\n' > docs/shelf/b.md
printf -- '-- schema\n' > src/schema.sql
mkdir -p shared guides; printf 'jobs: []\n' > shared/jobs.yml
printf '# guides\n- [x](x.md)\n' > guides/README.md; printf '# x\n' > guides/x.md
cat > "$L/project/agents.md" <<EOF
# roster
## Actors
| # | Role (one line) | Form | Domain | Roots | Memory | Shelf | Definition |
|---|---|---|---|---|---|---|---|
| A1 | Steward | native | governance | \`$L/project/\` · \`$L/shared/\` · \`.claude/\` · \`CLAUDE.md\` | \`$L/memory/a1/\` | — | system |
| A2 | Builder | session | code | \`src/\` · \`nowhere/\` | \`$L/memory/a2/\` | [shelf](../../docs/shelf/README.md) | [def](agents/agent-2.md) |
| A3 | Tester | session | tests | \`docs/\` | \`$L/memory/a3/\` | [gone](../../docs/nowhere/README.md) | — |
| A4 | Writer | session | docs | \`docs/\` | \`$L/memory/a4/\` | the docs folder, somewhere | — |
| A5 | Keeper | session | the guides | — | \`$L/memory/a5/\` | [guides](../../guides/README.md) | — |

## Write surfaces — who holds the pen
| Surface | Owner | When a handoff is NOT needed |
|---|---|---|
| \`src/schema.sql\` | A3 | an in-domain edit: the commit is the record |
| \`shared/jobs.yml\` | authored by the domain · applied by A3 | never |
| the \`events\` table | A2 | never |
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

# [8] STATUS-CHRONICLE (over the line budget)   [9] STALE-STATUS (the old commit date below) ·
#     STALE-STAMP negative: stamped after the build's commit day — not [9]'s (the writer mid-round, or a
#     wrong stamp: that one is [24]'s)   [24] FUTURE-DATE: a Last updated line's first date, read before the time
{ echo "# status"; echo "**Last updated:** 2099-08-02 09:00 UTC"; for i in $(seq 1 215); do echo "line $i"; done; } > "$L/memory/a2/STATUS.md"

# [11] TIER-3-LESSON · BAD-BOUND (a Bound: outside the eight)   [10] DANGLING-WIKI-LINK
# [24] FUTURE-DATE (a lesson stamped 2099-01-01 right after its id, with a legal Bound: TARGET beside it);
#      a negative: a day in a TITLE after a sound stamp is a word, not a stamp (L-A2-001 must NOT fire)
cat > "$L/memory/a2/LESSONS-LEARNED.md" <<EOF
# lessons
## L-A2-001 — 2026-09-01 — accepted_rule — always check twice, until the key expires 2099-12-31
no enforcement field here; see [[no-such-slug]]
**Bound:** NOWHERE
## L-A2-002 — 2099-01-01 — observation — stamped from the harness's notice
**What happened.** the date came from the notice, not from date -u
**Marked 2099-05-05** — an aging mark stamped the same way
**Bound:** TARGET
Enforcement: tier-2 (a variant of the one written form)
EOF

# [12] UNROTATED-LOG + ARCHIVABLE (a2)  ·  DECLARED-OVER (a3)
# [25] POINTER-FORM: a pointer in shape (not a finding), one as a heading, one with a fourth state;
#      a sentence of prose naming the word (not a finding: prose is not read)
# [11] ENFORCEMENT-FORM: a variant in a decision (`Tier 2 by design`) beside the one form
{ echo "# decisions"
  echo '- `ADR-A2-000` — ROTATED 2026-08-01 to archive/DECISIONS-archive-2026-08.md (done)'
  echo '### ADR-A2-000 — ROTATED 2026-08-01 to the archive (still in force)'
  echo '- `ADR-A2-000` — ROTATED 2026-08-01 to archive/DECISIONS-archive-2026-08.md (still in force)'
  echo 'A ruling whose prose says an entry was ROTATED is a sentence, not a pointer.'
  # [26] a pointer consolidated in a live entry, whose binds: line sits under that entry: carried, no conflict
  echo '- `D-007` — ROTATED 2026-08-01 to archive/DECISIONS-archive-2026-08.md (consolidated in `ADR-A2-001`)'
  echo '- `Q-0001` — ROTATED 2026-08-01 to archive/DECISIONS-archive-2026-08.md (done)'
  echo "## ADR-A2-001 — first"; echo "**Status:** superseded by ADR-A2-002"; echo "**Enforcement:** tier 2 — the atlas"
  # [26] a block in shape (own id, binds), a settled line with a fourth state (CARRIES-FORM), and
  #      ADR-A2-000 carried as binds: beside its settled pointer (CARRIER-CONFLICT); ADR-A2-001 is
  #      both binds: and settled: (a second CARRIER-CONFLICT)
  echo "**Carries.**"
  echo '- `ADR-A2-001` · keep the first · binds: fixture'
  echo '- `ADR-A2-001` · the first, once · settled: retired'
  echo '- `ADR-A2-000` · the oldest, kept alive · binds: fixture · tier 3 — nobody'
  echo '- `D-007` · the rule of the old scheme, carried on · binds: fixture'
  echo ""
  echo "## ADR-A2-002 — second"; echo "**Enforcement:** Tier 2 by design"
  # [11] ENFORCEMENT-FORM: the field written mid-line, after other text — no reader sees it
  echo "**Migration:** none. **Enforcement:** tier 2 — the atlas"
  # [26] a malformed own line: no disposition (CARRIES-FORM), so the entry has no carrier (NO-CARRIER)
  echo "**Carries.**"
  echo '- `ADR-A2-002` · the second, with no disposition'
  echo ""
  # [28] three claims: one naming a word of a product name, not the name (TIER-2-UNDETECTED); one
  #      whose field says tier 3 and mentions tier 2 later (not a claim); one naming the battery (resolves)
  echo "## ADR-A2-003 — third"; echo "**Enforcement:** tier 2 — the guard of the door"
  echo "**Carries.**"; echo '- `ADR-A2-003` · the third · settled: done'; echo ""
  echo "## ADR-A2-004 — fourth"; echo "**Enforcement:** tier 3 — nobody reads it; it becomes tier 2 at the next release"
  echo "**Carries.**"; echo '- `ADR-A2-004` · the fourth · settled: done'; echo ""
  echo "## ADR-A2-005 — fifth"; echo "**Enforcement:** tier 2 — the battery"
  echo "**Carries.**"; echo '- `ADR-A2-005` · the fifth · settled: done'; echo ""
  for i in $(seq 1 1210); do echo "l$i"; done; } > "$L/memory/a2/DECISIONS.md"
# [25] ARCHIVE-NAME: a day file under an older prefix
printf '# archive\nnothing headed here\n' > "$L/memory/a2/archive/LESSONS-archive-2026-08-01.md"

# [28] the detectors: one in shape (a2, enforces ADR-A2-000); one outside a<N>/ and one without a
#      head (DETECTOR-HEAD, twice); one reaching into a neighbour's folder (DETECTOR-CROSS-IMPORT);
#      three tier-2 claims that name nothing a detector resolves (TIER-2-UNDETECTED: the a2 decisions
#      "Tier 2 by design" and "the guard of the door", the a2 lesson "tier-2 (a variant …)")
mkdir -p "$L/checks/a2" "$L/checks/a3"
printf '#!/usr/bin/env bash\n# the rows of the oldest — a detector of AGENT 2\n# Enforces: ADR-A2-000\n# Reads: the rows\nexit 0\n' > "$L/checks/a2/rows-check.sh"
printf '#!/usr/bin/env bash\n# a neighbour'"'"'s helper, imported — a detector of AGENT 2\n# Enforces: ADR-A2-000\nsource .critos/checks/a3/lib.sh\nexit 0\n' > "$L/checks/a2/cross-check.sh"
printf '#!/usr/bin/env bash\n# no head here\nexit 0\n' > "$L/checks/a3/no-head.sh"
printf '#!/usr/bin/env bash\n# Enforces: ADR-A2-000\n# a stray file outside any agent folder\nexit 0\n' > "$L/checks/stray.sh"
# [26] TWO-HOMES: a pointer in a3 for an id that only a2's archive heads (a foreign pointer, in
#      shape); and a3's archive heading an id that a2's archive heads too (a copied entry)
{ echo "# decisions"; echo "> DECLARED EXEMPTION — ACTIVE: every entry here is cited"; echo "> alias: ADR-OLD-005 -> ADR-A3-001"; echo "> a retired sequence: ADR-LEG-NNN -> ADR-A3-NNN"
  echo '- `D-007` — ROTATED 2026-08-01 to archive/DECISIONS-archive-2026-08.md (done)'
  for i in $(seq 1 1210); do echo "l$i"; done
  # [27] IN-FORCE-BUDGET: one entry carrying three hundred rules in force; and no IN-FORCE.md in
  #      a2 nor a3 (IN-FORCE-STALE, twice)
  echo "## ADR-A3-001 — carries three hundred"; echo "**Enforcement:** tier 3 — the fixture, tiered by the field"; echo "**Carries.**"
  for i in $(seq 1 300); do echo "- \`ADR-A3-001\` · rule $i · binds: lane-$i"; done
  # [26] the carrier of D-009, headed in a3's archive outside the family's declared home (a2)
  echo '- `D-009` · carried here, headed outside its declared home · binds: fixture'
  echo ""
  # [26] UNTIERED: a rule in force with no tier on its line and no Enforcement: field in its entry
  echo "## ADR-A3-002 — untiered"; echo "**Carries.**"
  echo '- `ADR-A3-002` · a rule with no tier anywhere · binds: fixture'
  # [24] FUTURE-DATE, the stamp of an id heading read in its PLACE: trailing (ADR-A3-003) · inside a
  #      parenthesis after the id (ADR-A3-004); a negative: a title dated after a sound parenthesised
  #      stamp (ADR-A3-005 must NOT fire). Each carries itself settled, so no other check counts them.
  echo ""; echo "## ADR-A3-003 — stamped at the tail from the harness's notice — 2099-04-04"
  echo "**Enforcement:** tier 3 — the fixture, tiered by the field"; echo "**Carries.**"; echo '- `ADR-A3-003` · the trailing stamp · settled: done'; echo ""
  echo "## ADR-A3-004 (2099-05-05, accepted) — stamped in a parenthesis from the harness's notice"
  echo "**Enforcement:** tier 3 — the fixture, tiered by the field"; echo "**Carries.**"; echo '- `ADR-A3-004` · the parenthesised stamp · settled: done'; echo ""
  echo "## ADR-A3-005 (2026-08-01, accepted) — the certificate renews 2099-12-31: a day in the title is a word"
  echo "**Enforcement:** tier 3 — the fixture, tiered by the field"; echo "**Carries.**"; echo '- `ADR-A3-005` · the day in the title · settled: done'; } > "$L/memory/a3/DECISIONS.md"

mkdir -p "$L/memory/a3/archive"
# [24] a stub of the old pointer form, carried into the archive by a rotation (every archive reader skips
#      it): its stamp is the date after ROTATED
printf '# archive\n## ADR-A2-000 — a copy of an entry another folder heads\n## D-009 — a declared family headed outside its declared home\n## ADR-A3-006 — ROTATED 2099-06-06 to archive/DECISIONS-archive-2026-08.md (done)\n' > "$L/memory/a3/archive/DECISIONS-archive-2026-08.md"

# status-check axis 1: a dated STATUS beside a DECISIONS log (a3)
# [9] STALE-STAMP positive: stamped 2026-07-01, committed 2026-08-01 (the build's commit day)
# [24] negative: a future date in PROSE is a plan, not a stamp — it must NOT fire; nor a later date on
#      the Last updated line itself (the first after the colon is the stamp)
printf '# status
**Last updated:** 2026-07-01 (the next review is due 2099-01-15)
The certificate is valid to 2099-12-31 and the monthly run is scheduled after 2099-01-15.
' > "$L/memory/a3/STATUS.md"

# [13] MEMORY-SHAPE: a folder that is not a<N> (notes/) and an unrostered a<N> (a9/)
# [9] STALE-STAMP, a second positive: the stamp in the contract's plain form (the template writes it
#     bold), older than the build's commit day — read in both forms
echo x > "$L/memory/notes/x.md"; printf '# a9\nLast updated: 2026-07-01\n' > "$L/memory/a9/STATUS.md"
# the atlas's tree view: an ignored folder under a memory folder is neither tracked nor could be —
# it is not listed (the steward's measure once was)
printf '%s\n' "$L/memory/a2/measure/" > .gitignore
mkdir -p "$L/memory/a2/measure"; echo m > "$L/memory/a2/measure/x.txt"

# [8] NOTE-CHRONICLE: a per-entity note stacking dated headings, in a folder of its kind; the
#     kind's README.md beside it stacks them too and is not read; a note with one date is a photograph
mkdir -p "$L/memory/a2/notes/operators"
printf '# acme — operator\n## 2026-08-01 — first visit\nup\n## 2026-08-02 — second visit\nstill up\n## 2026-08-03 — third\ndown\n' > "$L/memory/a2/notes/operators/acme.md"
printf '# operators — the kind\n## 2026-08-01 — shape\n## 2026-08-02 — gates\n' > "$L/memory/a2/notes/operators/README.md"
printf '# beta — operator\nmeasured 2026-08-01: up\n## evidence\nthe capture of 2026-08-02\n' > "$L/memory/a2/notes/operators/beta.md"

# [10] AUTO-MEMORY-CITED: an auto-memory planted BESIDE the fixture (tests/run.sh points the leg at
#      it with CRITOS_AUTO_MEMORY), one note, cited from a tracked file in backticks
mkdir -p "$T.auto-memory/some-project/memory"
printf '# a planted note\n' > "$T.auto-memory/some-project/memory/planted-note.md"
printf 'The cluster facts are in `planted-note`, nowhere in this repo.\n' >> README.md

# [5] PING-PONG · NO-DONE-WHEN · MULTI-OWNER   [7] BAD-TOKEN · UNBOLDED-TOKEN
# [23] INBOX-ACTOR: AGENT 0 as a SENDER (upstream only receives) · AGENT 10, never rostered, as a
#      sender twice and a recipient once (the volley below) — a raise TO AGENT 0 is legal
# [24] FUTURE-DATE, one positive PER LEG: a token's date (the [ABSORBED 2099-… entry) · a register
#      verdict (ROADMAP, below) · an aging mark (the a2 lessons) · an id heading, one per PLACE of its
#      stamp (the a2 lessons, the a3 log and its archive) · a Last updated line (the a2 STATUS);
#      and a negative: an entry that QUOTES "Last updated:" with a future date must NOT fire
cat > "$L/shared/HANDOFFS.md" <<'EOF'
# inbox
- 2026-09-14 — AGENT 2 → AGENT 3: **[ABSORBED 2099-03-03 by A3 — a token stamped from the harness]** [docs/t.md]
- 2026-09-13 — AGENT 2 → AGENT 3: **[ACK]** my report names a `Last updated:` line dated 2099-02-02 — quoted, not a stamp [docs/r.md]
- 2026-09-12 — AGENT 0 → AGENT 2: **[ACK]** upstream never writes here [docs/raise.md]
- 2026-09-11 — AGENT 2 → AGENT 0: **[OPEN — method amendment: a lesson true on any project. Done when: the user has carried it upstream, or declined]** [docs/raise.md]
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
| R3 | a thing closed from the harness's day | A2 | closed 2099-04-04 |
EOF
printf '# contracts\n' > "$L/shared/CONTRACTS.md"

git add -A . >/dev/null 2>&1
GIT_AUTHOR_DATE="2026-08-01T00:00:00Z" GIT_COMMITTER_DATE="2026-08-01T00:00:00Z" \
  git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "fixture" >/dev/null
rm docs/gone.md
echo "fixture built: $T"
