---
name: crit-doc-lint
description: >-
  Run the deterministic documentation-hygiene battery — twenty-eight checks over links, orphan
  docs, the inbox and its actors, the roadmap, the memory logs, their forms, carriers and
  stamps, the generated law in force, the detectors, the pinned system tier, the agent
  definitions and the domains' roots in the tree.
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
bash ~/.claude/skills/crit-doc-lint/doc-lint.sh --own a4    # as a4: the generators it calls read every other folder as committed
```

An `--own` that names no memory folder — neither in the tree nor at HEAD — is answered with one
line and exit 2, as are the generators' folder arguments: a control that cannot answer says so.

Two rules hold for every check. A check that **could not run says `SKIPPED`**, never `(none)`: a
zero produced by a broken pipeline is not evidence. And every finding is a **flag for its owner,
never a gate**.

The output opens with the layout it found and a **provenance stamp** —
`### controls: CritOS@<tag-or-sha>[+dirty]`: which revision of the shared controls produced this
output. `+dirty` means the checkout the controls run from has uncommitted changes, so the output
may match no release.

Every check's block ends with its elapsed seconds — `(elapsed [n]: 412s)` — and the run ends
with the total and the stamp again: `### doc-lint done — 28 checks in 1830s · controls:
CritOS@…`. A slow run names the check that costs, not the run.

## The twenty-eight checks

1. **BROKEN** — a relative markdown link that does not resolve to an existing file. Code spans
   and fenced blocks are stripped first (a `](…)` fragment inside backticks is prose about
   links), and untracked `.md` files are scanned as sources too. Not detected, on purpose: a
   dead path written in backticks. Said first, before the links, **TRACKED-MISSING**: a path
   git tracks that is absent from the disk — an uncommitted deletion, yours or a neighbour's —
   once; every check reads the tree without it, and none dies on it.
2. **PATH-IN-CODE** — a top-level `doc/….md` path hard-coded in code: it goes stale the moment
   the doc moves (reference by ID or concept, never by path). Exempt: `/archive/` paths, and a
   line annotated **`doc-lint:allow path-in-code`** — reserved for a path that is the program's
   I/O target; the annotation states its reason.
3. **ORPHAN** — a tracked `.md` that no other tracked `.md` links to: the other half of the
   *no floating doc* rule. Docs found by convention are exempt (README / CLAUDE / AGENTS /
   SKILL, the memory triad and the generated `IN-FORCE.md` beside it, the three registers, per-entity notes under
   `.critos/memory/a<N>/notes/`); a repo declares its own families in `.claude/doc-lint-exempt`
   (one regex per line). **An index entry must be a real markdown link** — an index written in
   backticks is reachable by eye and orphaned by graph. Its second leg, **ORPHAN-BY-USE (WARN)**:
   linked is not read — a document whose inbound links all come from an index (`README.md`,
   `CLAUDE.md`) or a history surface (an archive, a memory log, the inbox, the roadmap, the
   generated indexes). A reader is sent by a `SKILL.md`, an agent definition, the roster, the
   contracts register or a live non-index document; nothing of those naming it, it is read by
   nobody — a procedure an agent runs is a skill, never a document. One hop, declared: a namer
   is not itself checked for being read. The pinned and project tiers, read by the boot, are not
   candidates; the `ORPHAN` exemptions apply.
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
   overwritten, not prepended; the fix is the owner's next checkpoint. Its second leg,
   **NOTE-CHRONICLE (WARN)**: the same fingerprint on every per-entity note under
   `.critos/memory/a<N>/notes/`, folders included — more than one dated heading. A note is the
   photograph of one entity, overwritten when it is touched (`contract-memory § 4`); no line
   budget, and each folder's `README.md` (the kind's contract) is not read.
9. **STALE-STATUS** — a `STATUS.md` whose last commit is ≥14 days old. It means *re-verify with
   the owner*, never *this is wrong*: a snapshot legitimately rests while its domain is quiet.
   **STALE-STAMP** — a `STATUS.md` whose `Last updated:` day is older than the day of its last
   commit, both UTC: the file changed after its head was stamped, and the boot trusts the head.
   The stamp is read bold (the template's form) or plain, at the line's start.
   A stamp newer than the commit is the writer mid-round, not a finding; a day later than today
   is `[24]`'s. New in 1.2.0: a WARN at this pin, a finding from the next release.
10. **DANGLING-WIKI-LINK (WARN)** — a `[[slug]]` that resolves nowhere reachable. A slug
    resolves against a heading in a tracked `.md`, a tracked doc's basename, a table row id, or
    `.claude/doc-lint-exempt` — never against the assistant's auto-memory: a link that resolved
    only there read green on the one machine that has it. Its second leg, **AUTO-MEMORY-CITED
    (WARN)**: a tracked `.md` naming, in backticks or a wiki-link, a note of this machine's
    auto-memory (every project folder under `~/.claude/projects/*/memory/`). A fact a tracked
    artifact needs lives in the repo (`contract-system § 3`): move it in and repoint. Declared
    bound: a true positive only where the note exists, silent elsewhere; archives and code are
    not read. `CRITOS_AUTO_MEMORY` names another root (the test suite plants one).
11. **TIER-3-LESSON** — an `accepted_rule` in a lessons log with no **`Enforcement: tier N`**
    field. The field is read at its syntactic position — a line that starts with it, list marker
    and bold admitted. A rule about controls that is itself enforced by hope is the failure this
    check exists for. Its second leg, **BAD-BOUND**: a lesson's optional `Bound:` field
    (`contract-memory § 3`) whose value is not one of the eight bounds of `contract-session § 6`
    — the field is optional, its value is not free. Its third leg, **ENFORCEMENT-FORM (WARN)**:
    the field outside its one written form — `**Enforcement:** tier N`, then nothing or an em
    dash and the detector — in a decision or a lesson; `tier-2`, `Tier 2`, a split *tier 2 for
    X, tier 3 for Y* are variants, reported and never gated (a split tier is two carried rules);
    a field written mid-line, after other text, is reported too: every reader reads the line's
    start, so nothing sees it.
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
    flagged: exempt it in `.claude/doc-lint-exempt`, or register the repo. The ids read are the
    method's grammar plus the families a project declares in `.critos/project/id-families`
    (one regex per line, optionally `· home: a<N>` after it) — a declared family is grammar,
    never an exemption: its ids must resolve too.
22. **ROOTS** — the roster's **`Roots`** column against the tracked tree (`contract-agent § 1`,
    `§ 3`): **UNROOTED** — files under no domain's root and no ruled surface (listed per
    top-level folder, a few names each; the count is the finding, the names the lead);
    **OVERLAP** — the same root declared by two actors (the most specific path wins only
    between *different* paths); **DANGLING** — a root matching nothing in the tree. A trailing
    `/` is a folder root, any other path a file root; `/` alone is the whole repo. Rooted by
    construction and never declared: `.critos/system/`, every `.critos/memory/a<N>/`, the
    generated atlas, and **the folder of each actor's Shelf index** (the first link of the
    Shelf cell, resolved from the roster's folder; a shelf at the repo root roots the whole
    repo) — the steward's one root that varies per project arrives that way. A ruled surface
    is a backticked path in the write-surface table's first column, on a row whose Owner cell
    names an actor **anywhere** (`applied by A6`, `**A6 — …**`) — a table or a service named
    there is not in the tree and is not read. Files are read tracked and
    untracked-not-ignored, like `[1]`. A roster
    **without the column says `SKIPPED`**: the column arrives with the migration, its cells with
    the user's ruling. Every finding is the steward's to route: an UNROOTED area is a root to
    register (the ruled Domain covers it) or a border to bring to the user (it does not).
23. **INBOX-ACTOR** — a live inbox entry whose **sender** is not a rostered agent, or whose
    **recipient** is neither rostered nor `AGENT 0`. The membrane (`contract-system § 0`): what
    enters the inbox is a builder's own entry, so its author must be an actor the roster names.
    `AGENT 0` is the reserved address of upstream (`contract-agent § 5`): a legal recipient of a
    raise, never a sender — an answer from upstream is a release, or the user's words. FYI
    readers are read as recipients. Live inbox only, **settled entries included**: a settled
    entry from such a sender still in the live inbox is history to rotate (the finding is the
    nudge); archives are records and are not read.
24. **FUTURE-DATE** — a stamp later than today (UTC) in a **stamp position** of a memory log,
    a `STATUS`, a register or their archives (`contract-system § 5`: a stamp is taken from
    `date -u` at the moment of stamping; the harness announces the machine's LOCAL day, which
    after 22:00 UTC is tomorrow; the registers sort by it). The positions: an inbox entry's
    head (`- YYYY-MM-DD —`), a lifecycle token's date (`[ABSORBED YYYY-MM-DD`,
    `[PARKED-OWNED YYYY-MM-DD`), every date on a heading that carries an id, every date on a
    `Last updated:` line, a register verdict (`done|closed|parked|superseded|re-verified
    YYYY-MM-DD`), an aging mark (`**Marked`, `**Rotated`, `**FACT-FLIP YYYY-MM-DD`). **Dates in
    prose are not read**: a live project carries the future on purpose — expiries, schedules,
    deadlines, reminders — and a check that read every date token cried wolf thirty times on
    zero wrong stamps. Bound, declared: a wrong stamp written anywhere else is not seen.
25. **POINTER-FORM** — a rotation pointer in a live memory log outside its one shape
    (`contract-memory § 2`): `- <id> — ROTATED YYYY-MM-DD to archive/<file> (<state>)`, the id
    in backticks, the state one of `done` · `superseded by <id>` · `consolidated in <id>`. A
    list line carrying ROTATED outside the shape, a heading in the stub's form (`— ROTATED
    YYYY-MM-DD to`), or a fourth state, is the finding; a heading whose title names the word
    is an entry, a sentence of prose that names the word is not read, nor is the fenced shape
    in a log's head. Its second
    leg, **ARCHIVE-NAME**: a file under
    `.critos/memory/a<N>/archive/` outside `DECISIONS-archive-YYYY-MM.md` and
    `LESSONS-LEARNED-archive-YYYY-MM.md` — a day file, a range, an older prefix, a `STATUS`.
26. **CARRIES** — the `Carries` block of every live entry (`contract-memory § 2`), read by the
    same parser as the law in force (`/crit-in-force --lines`). **NO-CARRIER**: a live entry
    with no line for its own id. **CARRIES-FORM**: a line under `**Carries.**` outside the two
    shapes, or a `settled:` state outside `done` · `superseded by <id>` · `consolidated in <id>`.
    **UNCARRIED**: an id headed in an archive with no live carrier — no pointer in the live log,
    no `Carries` line of a live entry; a pointer `consolidated in <id>` needs a `binds:` line
    somewhere live; the finding lands on the pointer that demands, at its line, or on the
    archive when no pointer exists. **CARRIER-CONFLICT**: one id carried as in force and as
    settled at once — a pointer consolidated in a live entry is not settled: the `binds:` line
    it demands is its carrier. **TWO-HOMES**: an id has one home, the folder whose archive heads
    it — an id headed in two folders' archives (a copied entry), or pointed from a folder whose
    own archive does not head it (the mark is the owner's; a split's new owner carries what it
    inherits in its founding block, never by pointer). A declared family may name its home on
    its line in `.critos/project/id-families` (`^D-[0-9]{3}$ · home: a2`): a heading of the
    family outside that folder — in an archive or a live log — is TWO-HOMES from the first
    heading, with no second archive to compare, and a declared home that is no memory folder
    is a finding on the line; an undeclared family's home stays derived from the archives.
    **HEADED-TWICE**: one id, one heading inside its home — an id headed more than once in one
    folder, its live logs and archives read together, a heading in the stub's form excluded
    (`— ROTATED YYYY-MM-DD to`: a stub of the old pointer shape is not an entry, and no archive
    reader counts it; a title that names the word is the entry it says it is). An
    amendment is a dated line in the entry's body (`**Amended YYYY-MM-DD (<id>):**`) or a new
    entry that cites it; a change of state moves in the heading's token and the Status
    paragraph; a stub is deleted at its rotation, never archived. **UNTIERED**: a `binds:`
    line with no `tier N` on the line and no `Enforcement:` field in its entry — the index
    prints `tier ?` and counts them in its head; a rule in force declares its tier. Pointers
    are read per folder. Fenced blocks are not read.
27. **IN-FORCE** — the generated law in force of every agent (`contract-memory § 6`), through
    `/crit-in-force --check`: **IN-FORCE-STALE** — `IN-FORCE.md` missing in a memory folder that
    holds a log, or differing from a fresh generation (a lane view beside it likewise);
    **IN-FORCE-BUDGET (WARN)** — past 300 lines (`.claude/doc-lint-in-force-lines` overrides):
    the signal to consolidate.
28. **DETECTOR** — a domain's detectors are a class of the method (`contract-session § 6`).
    **TIER-2-UNDETECTED**: a tier-2 claim — an `Enforcement:` field whose head says tier 2 (a
    tier-3 field that mentions tier 2 later is not a claim), or a `Carries` line with tier 2 —
    that names no detector which exists: neither a leg of the product by its stable name,
    matched whole (`STATUS-CHRONICLE`, the inbox guard, the battery, the status check; a word
    of a name is not the name, a number alone is not a name) nor a file under
    `.critos/checks/a<N>/` whose first lines say `Enforces: <id>`.
    **DETECTOR-HEAD**: a file under `.critos/checks/` outside `a<N>/`, or without the head, or
    whose head runs a machine path (a command in another repository of the project is named as
    `.claude/repos` declares it). **DETECTOR-CROSS-IMPORT**: a detector reaching into another
    agent's folder. The folders `.critos/checks/a<N>/` are rooted by construction for `[22]`;
    `templates/detector.sh.tmpl` is the contract as a bash skeleton.

**Several repos.** If the repo registers others in **`.claude/repos`** (one path per line,
relative to the repo root; `#` comments), the whole battery is repeated in each — read-only, one
level: a registered repo's own registry is not followed.

**Severity at birth** (`contract-system § 6`). A leg a release introduces reports as a **WARN**
in a project pinned at that release — its line ends *(WARN — new in X.Y.Z: a finding from the
next release)* — and as a finding from the next release on: one release of time to converge,
the pin after it the deadline. Born in 1.2.0: `[25]`, `[26]`, `[28]` and `IN-FORCE-STALE`. A
leg that is a WARN by a declared bound (`[8]`, `[10]`, the form legs, `ORPHAN-BY-USE`,
`IN-FORCE-BUDGET`) stays a WARN.

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
