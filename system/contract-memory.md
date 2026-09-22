# CONTRACT — What is mine (v1)

Three files per agent, in **one folder with exactly one writer**, at **`.critos/memory/a<N>/`**.
They are not three drawers of the same cabinet: they hold three different tenses, and only one of
them can lie.

## 0 · The invariant, and the three tenses

> **The invariant, stated once — every other mention in these contracts points here.**
> **One agent, one folder, one writer, one address.** The four are a single rule, not four:
> the folder is named by the agent number, so the mapping is one-to-one *by construction* and
> the roster does not have to prove it — it only has to agree with it.
>
> **A project applies this layout; it does not keep its own.** That is the whole of it, and it is
> deliberately stricter than the tooling requires: the controls can resolve co-located memory, and
> letting them would have bought one less move per migration at the price of two shapes in
> circulation, a per-project exception, and a roster-declaration to police. One shape, nothing to
> police.
>
> **An agent that owns several domains still owns ONE folder.** It merges. Measured on the first
> two real cases: one agent folded two folders, another three, and neither lost an id — because
> the fix for a multi-domain agent is a merge, not an exception to this rule. (The reverse — a
> domain that leaves its owner — is § 7.)

| | tense | written by | can it become false? |
|---|---|---|---|
| **`STATUS.md`** | **present** — what is true now | **overwrite** (the only one that deletes) | **yes** |
| **`DECISIONS.md`** | **past of our will** — what we chose | append | no |
| **`LESSONS-LEARNED.md`** | **past of the world** — what bit us | append | no |

**Only `STATUS` can lie** among the three — which is why the fact-flip exists (`contract-session §4`
owns the rule; it also covers register rows, which assert the present the same way). An
ADR says *"on 2026-07-24 we decided X"*: it can become irrelevant, never false.

**Where the overwritten text goes** — this is what makes overwrite safe rather than destructive. When
you remove a paragraph from `STATUS` it has exactly two destinations: it **carries a why** → it was
never `STATUS` material, move it to `DECISIONS` (a choice) or `LESSONS` (a discovery); it **does
not** → delete it, git has it. *The two append-only logs are the destination of what the snapshot
expels.* A `STATUS` that only grows is always this rule not being applied.

---

## 1 · STATUS — the snapshot

**It answers one question: what is true NOW.** It is overwritten, never prepended: the previous
answer is not history worth keeping, it is a **wrong answer**.

- **Sections:** `Now true` · `Next (my domain)` · `Proposals` · `Cleanup pending` ·
  `Last updated: YYYY-MM-DD`. No chronicle of past rounds. **At most one dated "as of" stamp** —
  the file's own.
- **`Next` is committed work only; what awaits a yes lives in `Proposals`.** The test, applied
  identically by anyone: *if nobody says yes, does it still have to happen?* Yes → `Next` (a
  parked item is committed work and carries its un-park trigger). No → `Proposals`: noticed,
  would do on the user's yes — **a yes moves it to `Next`, a no deletes it**. A proposal carries
  its **measure** (how many cases, what it costs): a proposal that cannot be decided from its own
  line is a wish. Optional — absent while empty. Tier 3, declared: a heading is read, not parsed.
- **It may not assert what is OPEN across agents.** Cross-agent obligations live in the inbox, which
  outranks it: `STATUS` *points* (`open items: see HANDOFFS`) and never enumerates. A snapshot that
  cannot assert what is open cannot assert it stalely — which is why *"what do I owe?"* is a **query,
  not a recall**.
- **It cites, it does not re-explain.** `The engine folds variants (ADR-A2-NNN)` — the fact here, the
  reasoning one hop away. A `STATUS` whose section headings are ADR events has become a second copy
  of `DECISIONS`.
- **Budget ~200 lines.** Past that you are keeping history in the wrong file.
- **Two write moments:** overwrite at checkpoint · fact-flip on the spot.

## 2 · DECISIONS — when an ADR is owed

**The test, stated once:** *could the next agent, in good faith, redo this differently?* If yes, it is
an ADR. A choice with one obvious answer — or one only a commit can be wrong about — is a commit
message.

**Reversibility is not the test.** A cheap-to-reverse choice still earns an ADR if it would otherwise
be re-litigated: what an ADR saves is the **re-deciding**, not the undoing. And a decision **the user
made in chat is always ADR-worthy** — it is the one class no future reader can reconstruct from the
code.

- **Minimum fields:** `ID · date (absolute) · status · decision (1 line) · why (1–3 lines)`, plus
  `supersedes / superseded-by` when it replaces one. Longer is fine; shorter is not an ADR.
- **Owner-keyed IDs** — **`ADR-A<N>-NNN`**: the prefix is the agent number, so the ID names its
  owner — and therefore its log — **by construction**, the same move § 0 makes for the folder. A
  subject prefix (`ADR-CRAWL-`) named a log only while logs were per-subject; after the one-folder
  merges it named a fragment (one real log held four subject prefixes). Each new prefix opens its
  own sequence at `001`; a log may hold several **closed** sequences (its history under earlier
  schemes) and exactly one live one — how many decisions a log holds is the atlas's business, not
  the ID's.
- **Legacy prefixes are grandfathered by default — never casually renamed.** An existing ID is
  cited from commit messages and archives that cannot or must not change: it stays valid as
  history and its sequence closes. (A bare `ADR-NNN` stays what it always was — ambiguous;
  grandfather it too.) The ID is self-locating **within its project**; across repos, cite it with
  the repo name (`<repo> ADR-A2-NNN`).
- **The one legal rename is a RETIREMENT MIGRATION.** A repo may retire a legacy sequence by
  renaming it to the owner scheme, only under all four conditions at once: it is **versioned** (a
  release, user-approved); it is **one repo in one commit** (a half-renamed repo is worse than an
  unrenamed one); the numbers are **kept**; and the log's header gains a **permanent alias table**
  — every retired ID must keep resolving forever, because the citations that cannot be edited are
  exactly the ones that outlive everything. When a log's single legacy sequence is retired this
  way, the live sequence **continues the numbering** (next = max+1) rather than opening a second
  `001`. Records (changelogs, dated audits, archives) are left verbatim: the alias table is what
  makes that safe.
- **Append-only, aged — and AGING IS MANAGED**, because this file sits in a boot read-path and
  everything ages: never delete; supersede, and **mark** what landed or was superseded so the log
  reads as history. Then **act on the marks**:
  - **The archive address is `.critos/memory/a<N>/archive/`** — files
    `DECISIONS-archive-<period>.md` (lessons likewise), moved with a pointer left behind. The atlas
    indexes archives exactly like live logs, so **an archived ID keeps resolving**; regenerate it
    in the same round.
  - **Two triggers, either suffices:** an entry **fully** superseded or completed (its Status says
    so — *superseded in part* stays live: its surviving half is still law to its owner) is
    archivable the round it is marked; and a log past the skimmable budget rotates its oldest
    regardless of status.
  - **Nothing is archived unmarked.** The move follows the mark, so the live log never silently
    loses an entry someone still believes current. The marks are the owner's; the move is
    structure, and the steward may perform it (`contract-agent § A1`).

## 3 · LESSONS-LEARNED — when a lesson is owed

**The bar:** an incident earns an entry when it **cost real time OR produced a wrong claim** — either
one, not both. Not "something happened"; not a restatement of a rule that exists — link that one.

- **Minimum fields:** `date · status · what happened (1–2 lines) · the rule (imperative, one line) ·
  Enforcement: tier-N`.
- **IDs: `L-A<N>-NNN`** — the same owner-keyed scheme, grandfathering and sequence rule as § 2.
- **Taxonomy:** `observation` (first sighting) → `candidate_rule` (second independent occurrence) →
  `accepted_rule` (recurred across actors, or the user confirmed it) → `deprecated`.
- **Every `accepted_rule` names its enforcement tier**, and if it is tier 3, says why no detector is
  possible. This is the field that keeps the file from becoming the place where good rules go to be
  ignored: the method's worst governance failure was *a lesson that had been written, promoted, and
  left at tier 3* — writing it down a second time would have changed nothing.
- Prefer **superseding** a near-twin over writing one: a lesson restated is a lesson that will drift.
- Same aging process as `DECISIONS` (§ 2): mark, then archive on either trigger, at the same address.

## 4 · Per-entity notes — the fourth file, and why it is not a fourth drawer

A domain that owns many similar things (sources, models, operators) accumulates knowledge that is
**true of one of them and useless for the others**. That is not a lesson: a lesson changes how you
act on the *next* entity, and this does not.

`memory/<agent>/notes/<entity>.md` — one writer (the folder's owner), free shape, dated entries.
**Not in the boot read-path**: it is opened when you touch that entity, never at boot, which is
exactly why it may grow without a budget while the three files may not.

The test, once: **would it change how you act on a DIFFERENT entity?** Yes → it is a lesson. No → it
is a note. If both — the general rule is genuinely separable — write both, and let the lesson cite
the note.

## 5 · There is no tier above this

A lesson is **local** — it belongs to the project that learned it — or it is **universal**, and a
universal lesson is **not memory at all**: it is a **proposal to amend the system tier** — raised
upstream (`contract-system § 3`) and, if adopted there, shipped as a versioned change.

There is deliberately **no intermediate shelf**. One existed and became a waiting room: rules that
should have become rules sat on it instead, one of its folders had no reader in any boot path, and
what it held turned out to be **copies** — the projects had kept the full text all along.

The trade is stated plainly: cross-project continuity for craft that is real but not yet ruleable is
lost. That is intended. **If it is worth carrying to another project, it is worth being a rule.**

## 6 · The index

A generated `MEMORY-INDEX.md` lists every ADR id, lesson id and memory folder as `id → file:line`.
It holds **addresses, never facts**, so it cannot become a competing truth — and it indexes the ids,
which are stable, while only *pointing* at the registers, whose rows churn daily.

It is **generated, never written**: a hand-edit disappears at the next run. Whoever appends an ADR or
a lesson regenerates it in the same round-close; a staleness check makes forgetting detectable.

**And the discipline is general to every index a project keeps, the hand-written ones included: an
index points at its target; it never describes it.** A description in an index is a copy that will
drift — one reference index described an identity contract as the *reverse* of what its own linked
target had said for two months, and no link checker can see that: both files exist and the link
resolves. Tier 3, declared: no detector reads a description against its target.

## 7 · When a domain changes hands — the split

The reverse of the merge: a domain has outgrown its owner and becomes a new agent's. *Whether*
that happens is the user's decision (`contract-agent § 4`); *how the living law changes hands*
is this.

- **Law moves by a FOUNDING BLOCK — never by pointer, never by moving entries.** A new agent
  that merely pointed at the old log could never mark what it supersedes — only a log's owner
  writes that mark (§ 2) — and the old owner would stay custodian of law it no longer
  understands. And an id names its owner by construction: it is never renamed, and an entry
  never changes log.
- **Three moves, each by its own writer.** ① The **previous owner** hands over: one inbox entry
  to the new agent listing the ids of the domain's decisions and lessons that are **still law**,
  plus the section of its `STATUS` it cedes. ② The **new agent**, in its first session, writes
  its founding block — its first ADRs consolidate that law, each naming the ids it consolidates
  — and its own `STATUS`. ③ The **previous owner** marks the originals *superseded by
  ADR-A‹new›-NNN*, drops the ceded section from its `STATUS`, and archives (§ 2).
- **Lessons travel the same way:** a superseding near-twin in the new log, the original
  `deprecated` (§ 3). **Pure history stays where it is**, reached by id: a record cannot become
  false, so who keeps it does not matter.
- **Split at a closed boundary of work**, never inside an open activity: a founding block
  consolidates living law, and law still being written is not yet law.
- **The steward's part is structure** (`contract-agent § A1`): the roster row, the write-surface
  rows for the new border, the memory folder, the atlas, and one inbox line telling every
  correspondent who the new addressee is. It writes none of the three moves.

Tier 3 for the procedure — no detector reads a handover; tier 2 for its result: every id a
founding block names must resolve (`/crit-doc-lint [21]`).
