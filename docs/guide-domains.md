<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Guide — cutting a project into domains

How to decide which agents a project should have, where the borders go, and when a partition has
stopped fitting. The steward works from this guide when it helps you set a project up
(`/crit-team`); you can read it to judge its proposals. Rationale and craft, read on demand —
where it and a contract disagree, **the contract wins**.

## 1 · Domains, not roles

Most multi-agent setups give each agent a **role**: a planner, a coder, a tester, a reviewer. A
role is a competence — what the agent can do. It owns nothing, so it remembers nothing worth
keeping between tasks, and it has no neighbour whose border it must respect.

CritOS gives each agent a **domain**: a slice of the system it **owns**, with its own memory and
a stated boundary (`contract-agent § 1`). Three things follow, and they are the point:

- **Memory accumulates where it is used.** The decisions about the billing engine live with the
  agent that owns the billing engine, and the next session starts from them.
- **The boundary prevents the overwrite.** *What I do NOT do* is the load-bearing field of a
  definition: the edge is where the neighbour begins.
- **Work is handed over, not lost.** What one owner needs from another goes through the inbox,
  with a closure criterion, and is counted until it is closed.

**Competences still have a place.** A reviewer, a security analyst, a one-shot migrator cut
*across* domains: they are `native` agents, invoked as a service, owning no slice
(`contract-agent § 2`). The steward is the first of them. A project is cut by domain; the
specialists walk across the cut.

## 2 · What a domain is

A slice of the system earns an owner when all three hold:

1. **It has a life of its own** — code or data that changes on its own rhythm, for its own reasons.
2. **Decisions accumulate in it** — choices a newcomer could in good faith redo differently.
   If nothing there would ever earn an ADR, there is nothing to remember.
3. **Its border can be named as a place** — a repo, a folder, a schema, a file where work
   meets. A border that can only be described as a list of tasks is not a border.

And what is **not** a domain: a competence (that is a native specialist) · an occasional activity
(that is a task inside someone's domain) · a slice so small its memory would stay empty (fold
it into its neighbour: a merge is cheap, `contract-memory § 0`).

**Start with one.** A single agent that owns the whole project is a legitimate partition. It
still gets the memory, the checks and the guard. The signals in § 4 tell you when one is no
longer enough — not a feeling that the project "should" have more agents.

**One exception, and it is not about size: how many sessions you keep open at once.** A memory
folder has exactly one writer. Two sessions of the same agent working at the same time are two
writers in one folder — so a user who works with two chats open needs two agents, however small
the project, and the question becomes where the border between them goes.

## 3 · Where the border goes when it is not obvious

**The folder is the first hypothesis, and often the wrong one.** A service in `apps/reporting/`
is also a deployed thing with secrets, roles and a nightly job: give the whole folder to a new
agent and you have handed it a second domain along with the first.

Ask instead **who decides what it means, and who keeps it running**. Two borders recur:

- **Meaning versus operation.** One agent owns what the numbers, the contracts and the
  vocabulary *mean*; another owns deploying, securing and scheduling it. The first writes the
  change, the second puts it in production — the same split as *a domain writes its migration,
  the platform owner applies it*.
- **Producer versus consumer.** Where one slice publishes something another reads, the border
  is the published surface, and it belongs to the producer.

Every border leaves a few things on it. **Name them explicitly, or they become nobody's**: list
each contested file or concern, give it to one side, and record it in the roster's write
surfaces (`contract-agent § 3`).

## 4 · The signals — measure before you propose

A partition is judged by numbers anyone can reproduce, never by impression. Each signal names
the command that produces it; **a proposal quotes its numbers and the command behind each**.
These are orders of magnitude to weigh together, not thresholds to trip. At a **first setup**
only the first and the fifth exist yet — there is no memory, no inbox, no roster to read — and
the rest of the evidence is what the user tells you about how they work and what hurts.

| Signal | What it suggests | How to measure |
|---|---|---|
| **One area takes most of an owner's commits** — for weeks, by a wide margin (several to one) | a domain inside the domain: a **split** | `git log --since=30.days --name-only --format= -- <the owner's paths> \| cut -d/ -f1-2 \| sort \| uniq -c \| sort -nr` |
| **A `STATUS` with separate sections** that never reference each other | the owner already keeps two notebooks: a **split** | read the owner's `STATUS.md` |
| **A log over budget because of one topic** | that topic is a domain: a **split** | `/crit-doc-lint` [12], then count the entries per topic |
| **An inbox centred on one agent**, most of it about one subject | the subject wants its own correspondent: a **split** | `grep -oE 'AGENT [0-9]+ → AGENT [0-9]+' .critos/shared/HANDOFFS.md \| sort \| uniq -c \| sort -nr` |
| **An active area no roster row covers** | a **gap**: a new agent, or a wider neighbour | the commit count above, against the roster's Domain column |
| **Two agents bouncing on the same border** | the border is in the wrong place, or undecided: move it, or **merge** | `/crit-doc-lint` [5] PING-PONG |
| **A memory that stays empty** — no decisions, a `STATUS` that never changes | the slice never was a domain: a **merge** | `/crit-memory-index`, the folder table |
| **A file several owners keep editing** | a contested surface: a **write-surface row**, not a new agent | `git log --format=%s -- <file>`, against the roster |

One signal alone is an observation. Two or three pointing the same way are a case.

## 5 · When to do it

**At a closed boundary of work, never inside an open activity** (`contract-memory § 7`). An
agent born while its domain's vocabulary is half-written inherits an open job instead of a
settled one, and the border gets drawn through work in progress. If the owner is finishing
something that defines the domain — a schema, a glossary, a rework — finish it first: what it
produces is the living law the new agent will be founded on.

## 6 · How it is done

- **A new agent** — the user decides it exists and its form; the definition is written from the
  template, all six fields, *what I do NOT do* included; the steward checks it against
  `contract-agent § 1`, adds the roster row and the memory folder (`contract-agent § 4`).
- **A split** — the law changes hands by a founding block, in three moves, each by its own
  writer (`contract-memory § 7`). Nothing is copied and no id is renamed.
- **A merge** — the absorbing agent keeps one folder and folds the other's logs into it; no id
  is lost (`contract-memory § 0`).

In all three **the steward proposes and conducts the structure; it never decides that an agent
exists and never writes a definition**. A custodian that appoints its own colleagues has stopped
being a custodian.
