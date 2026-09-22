# CONTRACT — What is everyone's (v1)

Three registers under `.critos/shared/`. Each holds **tier-3 content in a tier-1 shape**: the rows
are the work's, the grammar is this contract's — **cited by the file, never copied into it**.

> The shapes below are **parsed by position** by the deterministic controls. A register that deviates
> is not "slightly off": it is invisible to the counter that tells an agent what it owes.

---

## 1 · HANDOFFS — the inbox

Actors talk by **pull, not push**: you write one line, they read it at their next boot. Nobody edits
anyone else's files, nobody is messaged.

### Entry grammar

```
- YYYY-MM-DD — AGENT <N> → AGENT <M> (+AGENT <K> FYI): **[<TOKEN> — … Done when: <observable>]** <what changed → what the recipient must do>. [`ref`]
```

| Part | Rule | What breaks otherwise |
|---|---|---|
| `- YYYY-MM-DD ` | line starts with `- `, absolute date | the parsers split entries here; no date, no entry |
| `AGENT N → AGENT M` | a real arrow `→`, not `->` | sender and recipient are found by splitting on it |
| `(+AGENT K FYI)` | optional, extra readers only | **one owner per entry** — shared responsibility is held by nobody |
| `:` | one colon closing the participants | the token is read at the **first** colon; a colon before the arrow breaks the parse |
| `**[TOKEN …]**` | bolded, immediately after the colon | the token is read **at its position**, never searched for — an entry that merely *quotes* a token in its prose would otherwise count |
| `Done when: <observable>` | mandatory on `[OPEN]` | the measured cause of stale tokens: with no closure criterion the recipient **cannot know when to flip it** |
| the body | **one line** | the file is line-oriented; a multi-line entry is truncated at the first newline |
| **position** | a new entry is **PREPENDED** | the file is newest-first, and the boot protocol reads it top-down: an appended entry is read last and treated as old |

### The token vocabulary is CLOSED

**Live** — the recipient still owes something:
`[OPEN — … Done when: <observable>]` · `[PARKED-OWNED <date> by A<n> — … Park-trigger: <what un-parks it>]`

**Settled** — a record, may be rotated:
`[ABSORBED <date> by A<n>]` · `[ACK]` · `[CLOSED]` · `[SUPERSEDED by <ref>]` · `[RETRACTED]`.
A pure FYI needs no token.

**An invented token is invisible.** The counter recognises only the two live tokens and treats
everything else as settled — so an ask under `[GREEN-LIT …]` or `[URGENT …]` is *owed by someone and
counted by nobody*, and the next rotation buries it unread. This is measured, not feared: one real
inbox held 13 such entries, including a user-declared one addressed to the steward, unseen for six
days while the counter reported "0 owed by you".

### Three rules, in order of leverage

1. **Name who holds the pen on every write surface where domains meet, and state when a handoff is
   NOT needed.** *The
   owner does not revert an in-domain edit* — so an in-domain edit owes no entry: **the commit is the
   record.** This one rule removes most of the traffic. Measured cause: 27% of a real inbox was
   bounce traffic, and the worst topic ran 16 hops across 4 agents on a single file — not an
   ownership dispute but a notification storm.
2. **`Done when:` on every `[OPEN]`.** An `[OPEN]` that is actually done is **worse than no entry**:
   it re-litigates finished work.
3. **One owner per entry.**

**A handoff is a request for ACTION, never a receipt.** And **a bouncing topic needs a DECISION, not
another handoff** — repeated alternation means an unclear boundary or an undecided question, and more
handoffs only document the ambiguity one hop at a time.

### Reading, absorbing, rotating

Read **top-down, newest-first, in full, never grep-snippeted**. When you act on an entry addressed to
you: land the work **and** post a one-line ACK, or flip its token in place.

A1 rotates settled traffic to a dated archive. **Two classes never rotate:** live tokens, and any
entry whose token is **not in the vocabulary** — an unrecognised value must be found late, never
lost. **Rotation rebases relative links** (the archive sits one level deeper): re-check them after.

## 2 · ROADMAP — the shared forward register

The **one** place a shared or cross-domain effort is named. A development vertical to one domain
stays in that domain's memory.

```markdown
| Rx | What | Lead | Status |
|---|---|---|---|
| R1 | <one line, linking its design by ID — not restating it> | A2 | open |
```

- **Four columns, in this order** — axis 3 of the reconcile and the staleness net both parse **by
  position**.
- **`Rx` holds the id alone.** A struck row (`~~R7~~`) is skipped.
- **`Lead` names the owning agent(s)** (`A5 + A1`) — matched against the agent asking what is on its plan.
- **`Status` starts with its verdict word**: `open …` · `✅ done …` · `⏸ parked …` · `closed …` ·
  `superseded …`. A status may *mention* a settled leg while being open (`open (L1 shipped · L2
  deferred)`) — which is exactly why the verdict must come **first** and why the parsers anchor on it.
- **The row links, it does not restate.** A row that grows into a design is a copy that will drift.
- **Closure is the lead's, in the same round the work lands** — with proof, or as a one-line proposal
  to A1. Re-verifying an open row **touches** it, which resets its staleness clock: say so in the
  status cell (`⟳ re-verified YYYY-MM-DD`).

## 3 · CONTRACTS — the map that links

A **contract** is an iron rule that may not be violated except by an explicit human decision. They are
scattered by necessity — each enforced where it lives — so this register is the **single map**: it
**links to each source and never copies its text**. A contract with no row is invisible; a row that
restates its source is a copy that will drift.

Establish one → **enforce it at its source** *and* add one row. Change one → change the **source** (if
that source is user-locked, it needs the user).

**What earns a row — the placement test.** The register admits only a contract that is **mandatory
at project level or binds more than one agent across a boundary**; everything else lives where its
owner enforces it, and the register does not mirror it. Test every candidate row — and **split
first: a compound row is unclassifiable until each statement is its own atom** (one real row held a
substrate invariant and a project operations floor in one sentence; the questions below have no
answer for a molecule).

1. **Already law above this project — and does that law's SCOPE cover this statement?** A law that
   *names* a subject looks like a match; **only the scope decides** — the system tier's language
   invariant names project documents in the same sentence that delegates them to `settings.md`.
   Covered → no row: cite the law.
2. **The user's choice, rather than a rule of the work?** → `settings.md` keeps it (or the
   definition's standing-directives section, when it binds one agent).
3. **Enforced where, binding whom?** A row maps an **ENFORCEMENT**: its source cell names the place
   the rule bites — never a definition (that maps a *boundary*, which is the roster's business),
   and never its owner's own memory (that is this register mirroring a domain). Single-domain →
   the owner's docs and log, no row.

**The tiebreak is a rule, not prose.** A statement that is both the user's will and an enforced
convention: the **enforcement source holds the operative text**, this register **maps** it,
`settings.md` **keeps the choice**. Two readers must classify one row identically.

**A row that leaves, leaves a TOMBSTONE** naming where the rule now lives — the rule still binds;
only its tier moved. Tombstones get cited: a wrong departure reason teaches wrong law forever.

**Guards belong here too, as a section — not in a second register.** A guard is not a separate object
from a contract: it *is* the enforcement of one. And **register the teeth, not the existence**: every
guard row carries `BLOCKS` (the violation cannot proceed) or `FLAGS` (it proceeds and announces
itself). Three guards that looked identical in a real census were not — one failed the build, one
exited non-zero but was wired into nothing, and one printed a red banner and exited zero.

**Register the defect too.** A rule enforced by N hand-copied definitions with no module of record
gets the honest cell *"enforced at: no module of record"*. A register whose rows all look healthy is a
register nobody fixes.

**No counts in a register.** A number here is a snapshot, maintained by hand, and it will be wrong:
state the invariant and link the artifact that computes it. To know *how many*, run the thing that
counts.
