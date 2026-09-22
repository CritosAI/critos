# CONTRACT — The system (v1)

**Read this first.** It defines the world the other four contracts live in: what may change and
who may change it. The other contracts are its subsystems.

> **This file is not editable inside a project.** It is installed. A change is made upstream, by
> the CritOS maintainers, released as a new `VERSION`, and applied here by **A1** as a migration.
> Editing it in place produces a project running an unversioned mutant of the method.

---

## 1 · Three tiers

The tier is a property of the **content**, not of the folder. And what decides it is **who writes
it** — never what it is about.

| Tier | What it is | Who writes it | Where |
|---|---|---|---|
| **1 · system** | the rules that do not vary between projects | **nobody, inside the project** — a CritOS release, applied by an A1 migration | `.critos/system/` |
| **2 · project** | the choices *this* project made | the **user** (A1 maintains integrity) | `.critos/project/` |
| **3 · work** | what the work produces | the agents | `.critos/memory/`, `.critos/shared/`, and the project's own docs |

A file that mixes two tiers is the defect. The test: **if a file has to annotate one of its own
sections "(this rule really lives above)", it is copying a tier** — cite the tier instead; it has an
address.

## 2 · Who writes what

| File | Writer | If the wrong actor writes it |
|---|---|---|
| `.critos/system/**` | nobody in-project — it is INSTALLED. Written upstream by the CritOS maintainers, released, then applied here by A1 | the next migration overwrites it **silently** |
| `.claude/skills/**`, `.claude/hooks/**` | the installer only — **derived** | the edit disappears at the next migration, silently |
| `.claude/agents/agent-1.md` | derived from `system/install/` | same |
| `.claude/agents/agent-N.md` (native, tier-2) | the **user** authors it — the installer must never overwrite it | — |
| `project/settings.md` | **the user** — an agent proposes, never decides | an agent granting itself a directive |
| `project/agents.md` | the **user** creates/retires · **A1** maintains integrity | A1 *creating* an agent = self-expansion |
| `project/agents/agent-N.md` | the **user** authors · **A1** checks it against `contract-agent § 1` and the roster mapping | a definition written by its own agent = self-scoping |
| `memory/<agent>/` | **exactly one agent** per folder (A1 excepted, **structure only**) | two voices in a memory that reads as one |
| `shared/HANDOFFS.md` | each agent writes its **own** entries · A1 curates lifecycle | A1 authoring substance = a lossy translation hop |
| `shared/ROADMAP.md` | **A1** places the row · the **lead** flips their own | a row nobody closes re-litigates as "still to do" |
| `shared/CONTRACTS.md` | **A1** curates · agents propose · the source is elsewhere | a row with no source binds nothing |
| the project's own docs | the owning agent per the roster | domain content written by a non-owner |

**Derived files (`⟳`) have no writer, they have a producer.** The test: delete it and rebuild — if
nothing is lost, it is derived. A hand-edit to a derived file is destroyed at the next production,
**in silence**; and because it is derived, drift is *detectable* by comparing against its source
rather than by trusting anyone.

## 3 · Where do I write this? — the dispatch table

**One lookup.** Rows are read **top-down; the first match wins.** Most real moments match more than
one row — the commonest of all is *the user overrules you in chat*, which is a decision **and**
changes what is true now **and** may ripple. Precedence resolves it: the durable record first, the
snapshot after it, the notification after that. That moment is **one ADR plus whatever it makes
true** — never a choice between them.

| What you have | Goes to | Shape |
|---|---|---|
| A choice **another agent could in good faith redo differently** | your `DECISIONS.md` | ADR → `contract-memory` |
| What is true in my domain **right now** | your `STATUS.md` (overwrite) | snapshot → `contract-memory` |
| A per-entity operational note — it changes how you act on **that entity only** | `memory/<agent>/notes/<entity>.md` | free, dated → `contract-memory §4` |
| Something that **cost real time** or produced a wrong claim, and will recur | your `LESSONS-LEARNED.md` | lesson → `contract-memory` |
| A fact **another agent must act on or not undo** | `shared/HANDOFFS.md` | `[OPEN … Done when: <observable>]` |
| A **shared / cross-domain** effort spanning sessions | `shared/ROADMAP.md` | one Rx row (A1 places) |
| An **iron rule** you just established | enforce at its source **+** one `shared/CONTRACTS.md` row | one row, links only |
| A lesson **true on ANY project** | **not memory** — UPSTREAM, *through* **A1** and **by the user's hand**: a domain agent hands it to its steward, and **only A1 writes the entry**, addressed to `AGENT 0` — the reserved address for *upstream* (`contract-agent § 5`). It is the record, counted like any `[OPEN]`: `[OPEN — method amendment … Done when: the user has carried it upstream, or declined]` | you hand the evidence · A1 raises · the user carries |
| A user directive binding the whole project | `project/settings.md` | the user writes it |
| A fact about the **user** (a preference, a correction, an external reference) | the assistant's own auto-memory | one fact per file — **never** a second copy of what a domain's memory holds; on conflict **the repo wins** |
| A big analysis or design artifact | the project's own docs, **registered in their index** | — |
| A throwaway probe, a dump, a scratch note | nowhere — `_tmp_` prefix, then delete | it does not exist |

Four routings that are otherwise undecidable:

- **A decision spanning two domains** → the log of the agent who **owns the surface being changed**;
  the other gets an inbox line citing the ADR id. If neither owns it, it is cross-cutting: A1's log.
- **Lesson or per-entity note?** → would it change how you act on a *different* entity? Yes → lesson.
- **A universal lesson when you have no global role** → every agent is in this position: there is no
  role shelf. **The test:** does it depend on any project-specific tool, schema or vendor? Yes → it
  stays local. No → it is a method amendment, and it travels in two hops: a domain agent hands it to
  **A1** (its steward), and A1 raises it as the inbox entry the table row above names.
  **The entry is the record, not the delivery:** no path leads from a project to the CritOS
  maintainers — a project keeps no pointer to CritOS, CritOS keeps no list of its adopters — so
  **the user carries it upstream**, as every outward-facing act is the user's
  (`contract-session § 5`). A1 raises, the user carries; what becomes of it upstream reaches the
  project only as a release. One channel: two legs inside the project, the user's hand beyond it.
  (Tier 3, declared: a user's act has no detector — the entry stays counted in the project, and
  a raise the user forgets to carry is lost with nobody counting it.)
- **A claim of yours disproved mid-session** → fix it **on the spot**, with the date and the proof
  reference. Not at the next checkpoint.

## 4 · The vocabulary this method uses

Named once, because the other contracts invoke them as if they were common knowledge:

- **the controls** — the deterministic checks a project installs alongside these contracts. They read
  the shapes defined in `contract-shared` and the budgets in `contract-memory`. A rule with a control
  behind it is *tier 2*; one without is *tier 3* (`contract-session §6`).
- **the counter** — the control that answers *"what is owed BY ME?"* by parsing the inbox. It is the
  reason a `STATUS` may not assert what is open: the question is a **query**, not a recall.
- **the reconcile** — the control run before answering *"what is left?"*: it shows what landed in git
  since your `STATUS` was written, what the inbox says you owe, and which register rows you lead.
- **derived (`⟳`)** — a file with a producer instead of a writer (§2).
- **the guides** — the ~60% of the method that is rationale, incident evidence and craft rather than
  rule. They live in the CritOS repository (`docs/`), are **not installed**, and are read on
  demand: a contract states the rule and one line of why; the story is one hop away.

## 5 · Substrate invariants — not overridable

A project rule specializes or overrides a system rule, **except these three**. They are not editorial
preferences: they are the format of the substrate the method itself reads, parses and migrates.

1. **English** — everything under `.critos/`, always, whatever language the project's own documents
   use. `project/settings.md` governs the project's docs; it does not reach in here.
2. **UTC** for anything stored, compared or keyed. Local time only for human display.
3. **Absolute dates** (`2026-08-06`), never relative ("yesterday", "last week").

## 6 · Versioning and migration

`VERSION` is a **migration marker**, not a pin. A system change is an operating-system upgrade:
released upstream, by the CritOS maintainers, and applied here by A1.

**What a tier-1 change breaks is not the structure — it is the DATA already written under the
previous contract.** If v2 adds a required section to `STATUS`, every existing `STATUS` becomes
non-conforming: not wrong, written under another law. So every `CHANGELOG` entry carries two
mandatory fields:

- **Impact on existing data** — what stops conforming.
- **Migration** — `mechanical` (A1 applies it) · `owner-routed` (A1 routes it to each owner) · `none`.

**Classify a migration leg by WHAT CHANGES, never by whose file it is:** format conformance to the
loaded version is **`mechanical`** — A1 applies it, even on user-owned files (shape, heads, section
order, citation form); **content and boundary changes are `owner-routed`**. The releaser's caution
is not a classification criterion: the label is a behavioral switch, and A1 executes the label.

**A1 is the migration agent**, and one case needs a rule because it is a loop: **a migration that
changes A1's definition on either of its two surfaces — `contract-agent § A1`, or the installed
`agent-1.md` derived from it — is applied by A1, and then A1's session ends; what remains of the
migration belongs to its successor.** It may not apply its own redefinition and keep operating under
the previous one — and a redefinition can arrive on the file alone: a format release rewrites the
derived copy while the section stays byte-identical.

**A migration covers the project as it is declared, never one repo of it.** Every repo listed in
`.claude/repos` is inside the same migration, in the same round: its pinned tier, where it
carries one, moves to the same release; and every live surface there that names the layer's
paths, the controls or the changed text is re-pointed with the hub's. One level only, as the
declaration is (`contract-session § 1`). A satellite left behind runs an older law in the name of
the same project, and the pin check cannot see it — each repo is verified against the release it
declares, so the split is a finding of its own.

## 7 · These contracts, measured by their own rule

`contract-session §6` says a rule is at tier 1 (impossible), 2 (detected) or 3 (hoped for), and that
only the first two are engineering. Applied here, honestly:

| Rule | Tier | |
|---|---|---|
| the register shapes, the inbox grammar and vocabulary, the `STATUS` budget, the log budgets, the `Enforcement:` field | **2** | the controls parse them |
| `system/**` is not editable in-project | **2** — the release records a manifest (`releases.manifest`) and the pin-drift check compares a project's copy against **its declared version's** entries, never against CritOS's HEAD |
| the dispatch table, the six definition fields, who creates an agent, the substrate invariants | **3** | no detector exists; they are enforced by being read — except the definition's SECTION SHAPE (tier **2** via `[18]`) and its ACTOR leg (tier **2** via `[19]`) |
| one-writer-per-memory | **2** for the shape (the memory-shape check: every folder `a<N>`, every one rostered) — **3** for the writer itself, which no filesystem can attribute |
| the retirement signpost and the archive's closed vocabulary | **2** | `[16]` flags a live doc leaning on a ⚰ RETIRED file; `[17]` flags a live lifecycle token in cold storage — one invariant, two doors: a marker that retires a surface is read by every control that still counts it |
| a decision or lesson id cited anywhere resolves | **2** | `[21]` compares every cited id with the ids the logs declare, archives included — the citations that hold the logs together are checked, not trusted |

Stating this is not an apology: a contract that pretends to be enforced is worse than one that says
where it is only hoped for. The tier-3 rows are the roadmap for the next version.
