---
name: crit-doc-lint
description: >-
  Run the deterministic documentation-hygiene battery — twenty-one checks over links, orphan docs,
  the inbox, the roadmap, the memory logs, the pinned system tier and the agent definitions.
  The steward's cheap mechanical audit pass; use before a governance audit, at a session
  checkpoint, or after the doc tree was reorganised. The interpretive audits (redundancy,
  real drift, taxonomy, the cross-domain rollup) stay with the steward's own reasoning — this
  only runs the deterministic layer.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# crit-doc-lint

Run the mechanical documentation-hygiene checks and interpret the output.

## How to run
```
bash ~/.claude/skills/crit-doc-lint/doc-lint.sh
```

Two rules hold for every check. A check that **could not run says `SKIPPED`**, never `(none)`: a
zero produced by a broken pipeline is not evidence. And every finding is a **flag for its owner,
never a gate**.

The output opens with the layout it found and a **provenance stamp** —
`### controls: CritOS@<tag-or-sha>[+dirty]`: which revision of the shared controls produced this
output. `+dirty` means the checkout the controls run from has uncommitted changes, so the output
may match no release.

## The twenty-one checks

1. **BROKEN** — a relative markdown link that does not resolve to an existing file. Code spans
   and fenced blocks are stripped first (a `](…)` fragment inside backticks is prose about
   links), and untracked `.md` files are scanned as sources too. Not detected, on purpose: a
   dead path written in backticks.
2. **PATH-IN-CODE** — a top-level `doc/….md` path hard-coded in code: it goes stale the moment
   the doc moves (reference by ID or concept, never by path). Exempt: `/archive/` paths, and a
   line annotated **`doc-lint:allow path-in-code`** — reserved for a path that is the program's
   I/O target; the annotation states its reason.
3. **ORPHAN** — a tracked `.md` that no other tracked `.md` links to: the other half of the
   *no floating doc* rule. Docs found by convention are exempt (README / CLAUDE / AGENTS /
   SKILL, the memory triad, the three registers, per-entity notes under
   `.critos/memory/a<N>/notes/`); a repo declares its own families in `.claude/doc-lint-exempt`
   (one regex per line). **An index entry must be a real markdown link** — an index written in
   backticks is reachable by eye and orphaned by graph.
4. **DANGLING-SKILL** — a `/skill-name` referenced in the skill layer (`SKILL.md` files and
   `CLAUDE.md`) that is not installed: a dead pointer inside the text the model reads to choose
   a skill.
5. **INBOX hygiene** — on the live inbox and its archives: **ping-pong** topics (≥3 hops with
   ≥2 reversals — another handoff will not settle them: name the owner or take a decision),
   `[OPEN]` entries with no **`Done when:`**, and **diffused ownership** (an entry addressed to
   several agents is held by nobody). A **⚰ RETIRED** inbox — first line carries `⚰` or
   `RETIRED` — is a signpost, not a channel, and is not audited.
6. **STALE-Rx** — an open `ROADMAP` row untouched for ≥10 days, measured by `git blame` on the
   row. The net under the lead's flip duty (`contract-shared § 2`). A flag means *re-verify with
   the lead*; re-verifying touches the row and resets its clock.
7. **BAD-TOKEN** — an inbox lifecycle token outside the closed vocabulary (live: `OPEN`,
   `PARKED-OWNED` · settled: `ABSORBED`, `CLOSED`, `ACK`, `FYI`, `SUPERSEDED`, `RETRACTED`). The
   owed-counter treats everything but the two live tokens as settled, so an ask under an
   invented token is owed by someone and counted by nobody. Also reports a valid but
   **unbolded** token as a format defect.
8. **STATUS-CHRONICLE (WARN)** — a `STATUS.md` over the line budget (200; per-repo override in
   `.claude/doc-lint-status-lines`) or stacking more than one dated *as-of* section. A STATUS is
   overwritten, not prepended; the fix is the owner's next checkpoint.
9. **STALE-STATUS** — a `STATUS.md` whose last commit is ≥14 days old. It means *re-verify with
   the owner*, never *this is wrong*: a snapshot legitimately rests while its domain is quiet.
10. **DANGLING-WIKI-LINK (WARN)** — a `[[slug]]` that resolves nowhere reachable. A slug
    resolves against a heading in a tracked `.md`, a tracked doc's basename, a table row id, a
    machine-local auto-memory note name, or `.claude/doc-lint-exempt`. WARN, because one of those
    namespaces lives outside the repo.
11. **TIER-3-LESSON** — an `accepted_rule` in a lessons log with no **`Enforcement: tier-N`**
    field. The field is read at its syntactic position — a line that starts with it, list marker
    and bold admitted. A rule about controls that is itself enforced by hope is the failure this
    check exists for.
12. **UNROTATED-LOG (WARN)** — a `DECISIONS.md` or `LESSONS-LEARNED.md` past the skimmable budget
    (1,200 lines; override in `.claude/doc-lint-log-lines`). The remedy is **rotation, never
    deletion**: move the oldest entries to `archive/<NAME>-archive-<period>.md` and leave a
    pointer. A log whose cited entries must stay may **declare** its overage in its own head —
    `DECLARED EXEMPTION — ACTIVE` plus why (the state word is the predicate, case-sensitive) —
    and is then reported as `DECLARED-OVER`, never silent. Also prints **`ARCHIVABLE`** info
    lines: entries marked fully superseded or completed still in a live log
    (`contract-memory § 2`).
13. **MEMORY-SHAPE** — a `.critos/memory/` child that is not `a<N>`, or an `a<N>` folder that no
    roster row maps (`contract-memory § 0`: one agent, one folder, one writer, one address).
14. **PIN-DRIFT** — a pinned `.critos/system/` file that differs from, or is missing against,
    what its **declared** release shipped, per `releases.manifest`. Never compared against HEAD:
    a project pinned at an older release verifies against its own release. The manifest is found
    from where the control itself lives — the project keeps no pointer to CritOS. Every
    can't-verify branch says `SKIPPED`. In the CritOS repository itself the check skips.
    Its second predicate, **VERSION-SPLIT**: a repo registered in `.claude/repos` whose pinned
    tier declares another release than this one — a migration covers the project as it is
    declared (`contract-system § 6`), and each repo's own pin check, verifying against the
    release it declares, cannot see the split. Read from the hub, one level.
15. **DEFINITION-PATH** — a `.md` path or an absolute path in an agent definition. A definition
    names its perimeter, never its interior (`contract-agent § 1`). Only these two classes are
    wrong without judgment; perimeter-versus-interior depth is the steward's review.
16. **RETIRED-REF** — a live doc whose link resolves to a file whose first line carries the
    ⚰/`RETIRED` marker: the link resolves, so [1] is green by design. Sources under `archive/`
    or `release/`, and the signposts themselves, are exempt. Most hits are legitimate history —
    triage, never a gate.
17. **COLD-LIVE-TOKEN** — an `[OPEN]` or `[PARKED-OWNED]` token in the token position of an
    ENTRY inside a `HANDOFFS` archive: owed by someone, counted by nobody, because the
    owed-counter reads the live inbox only. Restore a truly live entry, or close it where it
    lies. A line that only QUOTES the token — prose, or a settled entry retelling its past — is
    not a finding: those are counted on one line, never listed.
18. **DEFINITION-SHAPE** — an agent definition whose `##` sections differ from the template's:
    four mandatory (`1 · Purpose`, `2 · Domain`, `3 · What I do NOT do`,
    `4 · Write surfaces I touch`) plus the optional `5 · Standing directives`.
19. **DEFINITION-ACTOR** — a definition naming an actor other than itself. A definition names
    **domains, never actors** (`contract-agent § 1`); the roster resolves domain → agent.
20. **SHELF-INDEX** — a rostered **Shelf** address that does not resolve, or a README-indexed
    shelf folder holding tracked `.md` not reachable from the **index chain** (the index plus
    the READMEs it links, transitively; a link from a non-index sibling does not count). The
    list leg runs on `README.md` indexes only — any other entry point is legal and its
    completeness is the owner's. A shelf declared in prose with no link is itself a finding,
    unless the cell names another repo.
21. **CITED-ID** — a decision or lesson id (`ADR-…-NNN`, `L-…-NNN`) cited in a doc, a register
    or code that no `DECISIONS` / `LESSONS-LEARNED` log declares. Declared = a log's entry
    headings, archives included, plus the ids in a log's head (the alias table of a retired
    sequence; a whole sequence retired as `ADR-OLD-NNN -> ADR-A2-NNN` resolves every id of the
    prefix on the LEFT of the arrow, and only that one — the right side is the live sequence,
    where a typo must still fire), across every registered repo. Not read as citations: the pinned tier, the skills,
    templates, archives and the generated atlas. A rotation, a restructure and a split
    (`contract-memory § 7`) are the moments an id gets lost. An id of an unregistered repo is
    flagged: exempt it in `.claude/doc-lint-exempt`, or register the repo.

**Several repos.** If the repo registers others in **`.claude/repos`** (one path per line,
relative to the repo root; `#` comments), the whole battery is repeated in each — read-only, one
level: a registered repo's own registry is not followed.

## How to act on the output (the steward)

- **A finding on a surface you own** (doc organisation, registration, a moved path to re-point)
  → fix it and commit locally.
- **A finding on a domain's doc or code** → it is the owning agent's: write one line in the
  inbox (`.critos/shared/HANDOFFS.md`) and report it. Do not edit domain content.
- **A finding is a symptom** (`contract-session § 6`, ACTION): read its shape before choosing
  the action — the same broken link is repointed when its target moved and de-linked when its
  target died; a red on a pinned file asks for a migration, never an edit.
- Then apply the interpretive audits the script does not cover — redundancy, real drift, which
  doc is authoritative — with your own judgment.
