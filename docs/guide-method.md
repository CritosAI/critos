<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Guide — the method in ten ideas

The five contracts in `system/` are the rules. This is the reasoning behind them, short enough to
read once. Where it and a contract disagree, **the contract wins**.

## 1 · An agent is an owner, not a persona

An agent is a named owner of a slice of the system, with its own memory and a stated boundary
(`contract-agent § 1`). What makes a team of agents work is the same thing that makes a team of
people work: everyone knows what is theirs, and where the neighbour begins. The load-bearing
field of a definition is ***what I do NOT do*** — a boundary stated only as "what I own" has no
edge. How to find the slices: [cutting a project into domains](guide-domains.md).

## 2 · Every session starts from zero — so the boot is a contract

An agent remembers nothing between sessions: everything it knows, it read at boot; everything
the next one will know, it must write before leaving. The boot order (`contract-session § 1`) is
functional, not alphabetical — *the school · the company · yourself · the others · what you may
never break · what you have · what is owed · where you left off*. Two choices in it are
deliberate: the **forbidden is read before the asked** (a request absorbed before its rails are
loaded is how a rail gets crossed in good faith), and the **inbox before your own status** (your
status is hearsay about what you owe).

## 3 · Memory has three tenses, and only one can lie

`STATUS` is the **present**: what is true now — overwritten, never prepended, because the
previous answer is not history, it is a wrong answer. `DECISIONS` is the **past of our will**:
what we chose and why, append-only. `LESSONS-LEARNED` is the **past of the world**: what bit us,
append-only. A decision can become irrelevant, never false; only a status can lie — which is why
a status claim disproved by evidence is corrected on the spot, with the proof
(`contract-session § 4`), and why a status may point at what is open but never enumerate it.

The test for a decision record: *could the next agent, in good faith, redo this differently?*
What an ADR saves is the re-deciding, not the undoing.

## 4 · One folder, one writer

Each agent writes exactly one memory folder, and nobody else writes it (`contract-memory § 0`).
Two voices in a memory that reads as one is how a project ends up with a confident, wrong past.
The consequences reach far: two sessions open at once are two agents; an agent that absorbs a
domain merges the memories; a domain that leaves its owner is handed over by a founding block,
not by copying (`contract-memory § 7`).

## 5 · Agents talk by pull, not push

Nobody edits anyone else's files, and nobody is messaged: you write **one line** in the shared
inbox and the recipient reads it at its next boot (`contract-shared § 1`). Three rules carry
almost all the value:

- **Name who holds the pen** on every file where domains meet, and say when a handoff is *not*
  needed — an in-domain edit owes nobody a line: the commit is the record. This alone removes
  most of the traffic.
- **`Done when:` on every open request.** Without a closure criterion the recipient cannot know
  when to close it, so it goes stale, and finished work gets re-litigated.
- **One owner per entry.** A request addressed to two agents is held by neither.

A request is for **action**, never a receipt. And a topic that keeps bouncing between two agents
does not need another handoff: it needs a **decision** — about a border, or about the question.

## 6 · "What do I owe?" is a query, never a recall

A status that says "blocked on others" may be a week out of date while the other agent has
answered and is waiting. So the question is answered by **counting the inbox**
(`/crit-status-check`), not by reading one's own memory — and the vocabulary of inbox tokens is
**closed**, because an ask written under an invented token is owed by someone and counted by
nobody.

## 7 · A register is a map: it links, it never copies

Three shared registers — the inbox, the roadmap, the register of iron rules. Each points at
where the substance lives and never restates it: a copied fact drifts, and then there are two
truths. For the same reason there are **no counts in a register** — to know how many, run the
thing that counts. In code, cite a decision by its **id**, never by a file path: paths move.

## 8 · A rule is not a control

Every rule sits at one of three tiers (`contract-session § 6`): **1** the violation cannot be
expressed · **2** a script detects it whether or not anyone remembered · **3** written down and
hoped for. Only the first two are engineering. A tier-3 rule fails silently, and the failure is
invisible precisely because everyone believes the rule is in place. CritOS says, for each of its
own rules, which tier it is at (`contract-system § 7`) — and its checks **flag, never block**: a
check that blocks gets switched off at its first false positive; one that flags survives.

## 9 · A green is evidence only within its bounds

A verification proves what it exercised, when it ran, at the layer it ran — and nothing else
(`contract-session § 6`, eight bounds). The two that pay for themselves first: **a detector's
zero is not evidence until the detector has been seen firing** on a known positive; and **a
finding is a symptom, not a diagnosis** — read its shape before acting on its label. CritOS's own
tests are built this way: every check has a fixture it must fire on (`tests/`).

## 10 · The user's hands

Some acts are the user's, even when a request seems to imply them (`contract-session § 5`):
`git push`, builds and deploys, heavy or real runs, production writes, anything destructive or
visible outside the machine. The agent **stops at the local commit** and says "ready for you to
push". And in a worktree shared by several sessions there is one git index: stage and commit
by **explicit pathspec**, never `add -A`, `stash`, `commit -a`, `checkout .`, `clean -fd`.

---

**People who are not agents.** A human who works on part of the project — in a repo of their
own, say — has no roster number and no memory folder. They work inside one agent's perimeter,
and that agent is the single bridge: what they need from the rest of the project goes through
its inbox, in its name.

**Several repos.** A project that spans repos lists them in `.claude/repos`, one path per line;
the checks and the owed-counter then cover each of them, and a migration runs in each of them,
in the same round — a satellite that still declares the previous release is a finding. One level
only: a listed repo's own list is not followed.
