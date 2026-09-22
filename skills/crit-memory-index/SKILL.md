---
name: crit-memory-index
description: >-
  Generate MEMORY-INDEX.md — the deterministic, read-only ATLAS of a project's memory: every ADR ID,
  every lesson ID, each memory folder with its writer and size, and the registers, each as a
  file:line POINTER. Use when a project's memory has grown past what an agent can read at boot, when
  you need to find which log owns a fact, or in a round-close to keep the atlas fresh (--check tells
  you if it is stale). It holds no facts, only addresses — so it cannot drift into a second source of
  truth. Never hand-edit it; regenerate it.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# memory-index

**What it is.** One generated file at the repo root, `MEMORY-INDEX.md`, listing *where every
durable fact lives* — never the facts themselves.

**Why it exists.** Boot cost grows with accumulated memory (the reference implementation passed
~28,000 lines across 9 memory triples). Two failures follow: an agent cannot afford to read what
the onboarding protocol tells it to read, and a fact it needs but does not know exists is
unfindable. The ecosystem's usual answer — a wiki, a knowledge graph, a vector store — is a
**second store**: it takes the memory out of git, out of diff review, and out of one-source-of-truth.
This is the cheap 80% of that idea with none of the cost.

**The rule that keeps it safe: it holds ADDRESSES, not facts.** Every line is
`<id> → <file>:<line>`, harvested from the files themselves. Nothing in it can contradict a source,
because it asserts nothing. If it disagrees with a source, the source wins and the index is stale —
regenerate it.

## Use

```bash
bash ~/.claude/skills/crit-memory-index/memory-index.sh            # rewrite MEMORY-INDEX.md
bash ~/.claude/skills/crit-memory-index/memory-index.sh --check    # verdict: 0 fresh · 1 STALE-ID · 2 STALE-COUNT
```

**The `--check` verdict is SPLIT, because the defect is in the verdict, not the frequency.** A
single binary STALE reported *an id whose address moved* (the atlas sends a reader to a DIFFERENT
entry — silent mis-citation) identically to *a count changing in the folder table* — and almost
every checkpoint changes a count, so with several writers the file was red more often than it was
wrong, and a detector that cannot separate danger from bookkeeping trains people to ignore it.
Now: **STALE-ID (exit 1, danger)** — an id moved, appeared or vanished; regenerate THIS round.
**STALE-COUNT (exit 2, bookkeeping)** — only counts/cells moved, every id still resolves;
regenerate at the round-close. A hook that regenerated on every commit would fix the schedule and
leave the verdict blind — the fix is the verdict. (The `L<n>` in a pointer line is a jump hint,
never a citable address: resolve an id by grep in the file the atlas names.)

## Rules

- **Generated — never hand-edited.** An edit is lost on the next run, and a hand-written line would
  be exactly the copy this design exists to avoid.
- **Never cite it as a source.** Cite what it points at (an ADR ID, a lesson ID, a register row).
  It is a finding aid, not an authority.
- **Regenerate when a log grows** — a per-round close after appending an ADR/lesson, or at a
  checkpoint. `--check` answers "did I forget?".
- **Commit it.** It is cheap, and a stale committed index is visible in a diff, whereas an
  uncommitted one silently does not exist for the next agent.
- **Owners come from the roster**, harvested — not restated here. A folder the roster does not map
  prints `(unmapped)`: an honest gap the steward can then fix in the roster, rather than a guess.
