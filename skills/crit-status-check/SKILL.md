---
name: crit-status-check
description: >-
  "Fai il punto" — before you tell the user (or yourself) what's left on your plan, reconcile
  your STATUS against reality on BOTH axes: git (what landed that STATUS doesn't know) and the
  shared inbox (what is OWED BY YOU that STATUS may call "blocked on others"). Runs a deterministic
  pass so you answer from truth, not from a possibly stale STATUS. Use whenever asked "what's left /
  where are we / dammi lo stato del piano", at the start of planning, or when a STATUS feels old.
  The script is read-only; the protocol then requires the FACT-FLIP: a STATUS claim disproved by
  this run's evidence is corrected on the spot (date + proof ref). The narrative rewrite of STATUS
  stays /crit-checkpoint's.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# status-check

The status-check protocol, operationalised. Never narrate your plan from memory — reconcile first.

**There are TWO ways a STATUS lies, and you need a check for each:**

| Axis | The lie | The check |
|---|---|---|
| **STATUS vs GIT** | "still to build" — but it already landed | commits touching your domain since STATUS was written |
| **STATUS vs INBOX** | "blocked on others" — but *they answered and are waiting on YOU* | `[OPEN]` handoffs addressed to you |

Axis 2 was added after a live incident: a steward reported its open items as *"all blocked on
others"* while **ten** `[OPEN]` handoffs sat in the inbox addressed to it — one for **10 days**,
another already answered five days earlier by an agent who was waiting. Its STATUS had **not**
drifted from git, so the git check was green. It had drifted from the **inbox**. A git-only check
is structurally blind to this.

> **The inbox outranks the snapshot.** "What do I owe?" is a **query**, never a memory.

## How to run
```
bash ~/.claude/skills/crit-status-check/status-check.sh --me <N> <memory-folder> --domain <code-path>
```
Pass your agent number with `--me` (it is also inferred from a `.critos/memory/a<N>` argument) and
the memory folder you own — the roster's Memory column names it. **Also pass
`--domain <code-path>` (repeatable):** a memory folder says nothing about which code its agent
owns, so without it axis 1 scopes git to the memory folder and warns `SUSPECT` — **whether or not
commits appear**. The populated case is the dangerous one: the checkpoint that dates the window
is itself a memory commit, so a memory-scoped list is almost never empty, and it reads as an
answer while being the wrong axis. Example:
`bash ~/.claude/skills/crit-status-check/status-check.sh --me 4 .critos/memory/a4 --domain packages/<your-domain>`

**Without `--me` the inbox axis is SKIPPED** and you are answering "what's left" from git alone —
which cannot see what another agent is waiting on you for. The script says so loudly; re-run it.

It prints, per domain: the STATUS file + how many days stale, the **commits since STATUS was
written**, and the **ADR headers** from the sibling `DECISIONS.md`. Then, for you: every **live
`[OPEN]` / `[PARKED-OWNED]` handoff addressed to you**, in **full text** (never grep-snippeted —
grep renders long entries as `[Omitted long matching line]` and silently hides the ones you most
need), each with its **age**, and a `*** STALE ***` flag past `--stale-days` (default 4).
Entries **you sent** are excluded — your own broadcast is not your homework.

**The constellation.** If the repo registers its sibling repos in **`.claude/repos`** (see the
method's *Multi-repo constellation* convention), the inbox axis is then **repeated in
every registered repo** — an `[OPEN]` addressed to you in a satellite repo's inbox is owed by you
exactly like one at home, and without this it is structurally invisible from where you booted.
The git axis stays home-repo-scoped (domain paths are relative to where you run).

## The answer format — "what's on your plan?" (three labeled buckets)

The user must be able to tell WHAT TIER each open item is. A flat task soup ("I have X, Y, Z…")
hides whether an item is a debt, a shared effort, or a private micro-step — so the answer is
**always structured in three labeled buckets**, each fed by its own deterministic source:

| Bucket | What goes in it | Fed by |
|---|---|---|
| **[OWED]** | `[OPEN]` inbox entries addressed to you — debts to other agents | axis 2 (inbox, incl. constellation) |
| **[SHARED]** | open ROADMAP items you lead — named, multi-session efforts | axis 3 (roadmap scan) |
| **[DOMAIN]** | your own STATUS worksheet intentions — micro-steps, the *how* is yours | your STATUS `Next (my domain)` |
| **Proposals** | choices awaiting the user's yes or no, each with its measure — not a tier of your plan, so it carries no bucket tag | your STATUS `Proposals` section |

Never mix tiers, never present a [DOMAIN] micro-step and a [SHARED] roadmap item as peers — and
never present a proposal inside [DOMAIN]: committed work and work awaiting a yes are different tenses.
A **named effort** sitting only in your STATUS (a tranche, a migration, a new strategy — anything
multi-session another actor might need to see coming) is a visibility gap: **propose it for a
ROADMAP row via HANDOFFS — the steward decides the tier** (domain-only vs shared) and places it.

## The protocol (what you do with the output)
1. **Reconcile against git.** For each commit listed: is it reflected in STATUS? If a build shows
   the work landed, it is **DONE** — not a candidate to propose. For each ADR still marked
   proposed / in-flight, check whether the commits show it landed.
2. **Reconcile against the inbox.** Every entry the script lists is **owed BY YOU**. Read each one
   *whole*. **Never report one as "blocked on others" without reading it** — that is the exact
   failure this axis exists to prevent. Close each with an `[ABSORBED … by A<N>]` flip or a
   one-line ACK. A `*** STALE ***` flag means it has sat unACKed: it is very likely already done
   and merely carrying a dead token, which is *worse* than no entry — it re-litigates.
3. **Answer forward-only.** Give a TODO / what's-missing list — **no past chronicle**.
4. **Fact-flip the drift NOW — don't report a lie and leave it in the file.** If STATUS asserts
   something this run just **disproved with evidence** (says "in flight" — the commit is right
   there; says "blocked on others" — the inbox entry was absorbed), edit **that claim** immediately:
   mark it done/closed with the date + the commit hash (or inbox ref) that proves it, and commit.
   **This scope includes the axis-3 roadmap rows you lead**: if a row prints as open and you KNOW
   the work landed (your own ADR/commits prove it), the flip is owed *this session* — flip it
   yourself if the register is yours, otherwise send the steward the one-line flip proposal with
   the proof. A closed effort reported as open to the user is the exact failure this rule exists
   for (it happened: a roadmap row sat "decision pending" for 11 days after the decision shipped).
   Reporting "X is already closed, STATUS doesn't know yet" *while leaving STATUS wrong* is absurd:
   the next session re-reads the known lie and re-discovers the same drift. Same principle as the
   inbox's Absorb-or-ACK — you flip a token when you **verify** it, not at session end.
   **The line this must not cross:** a fact-flip corrects a claim against evidence produced by THIS
   run. Re-narrating the state, re-planning forward work, reshaping the file — that is a **rewrite**,
   it needs end-of-session context, and it stays `/crit-checkpoint`'s job. When in doubt whether an edit
   is a flip or a rewrite, it's a rewrite: say so and leave it to `/crit-checkpoint`.

## Boundaries
- **The SCRIPT is read-only** — it never writes; it surfaces. The **agent** then owes one write class
  on the spot: the **fact-flip** (protocol step 4 — a claim disproved by this run's evidence, corrected
  with the proof attached). Everything heavier — the narrative rewrite of STATUS, appending
  DECISIONS/LESSONS — stays `/crit-checkpoint`'s, at a session boundary with full context.
- The deterministic layer (this script) only shows git-vs-STATUS divergence; the *judgment* — is a
  claim really stale, what's genuinely left — stays yours.
- The script reads the date on the STATUS line that mentions "updated"; if it finds none it says
  so and skips the git axis rather than guess a window.

## Related
- `/crit-doc-lint` — mechanical doc hygiene (broken links, path-in-code). Different axis (link integrity,
  not plan freshness); run both at a checkpoint.
- `/crit-checkpoint` — the write side: reconcile then rewrite STATUS/DECISIONS to truth.
