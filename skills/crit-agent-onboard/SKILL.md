---
name: crit-agent-onboard
description: >-
  Turn a fresh chat into one of the agents rostered in THIS repo. Use at the START of a new
  session when you were NOT handed a RESTART block: it reads the roster, lets you pick, runs the
  boot order from the session contract including the agent's own definition, and gives a short
  in-role report. It REFUSES rather than improvise: if the roster or the chosen agent's
  definition cannot be found, it stops and names what is missing — and it refuses any agent the
  roster does not list. The "open" bookend to /crit-checkpoint. The steward is native — invoked via the Agent tool,
  not booted here.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# crit-agent-onboard

Boot a fresh chat into a specific agent. This is the interactive front door to the boot order in
**`contract-session.md § 1`** — it reads the roster, lets you choose, and performs the read
sequence so the chat starts in-role.

> **Single source.** The boot ORDER is a contract; the ROSTER is the project's. This skill
> restates neither. If it and the contract disagree, **the contract wins**; if it and the roster
> disagree, **the roster wins**.

## The rule that governs every step below

**A boot that cannot find its inputs must FAIL, loudly, and stop.**

This skill's product is a chat that *believes* it is an agent, and that belief is acted on for
the rest of the session. A boot assembled from files that were not there is worse than no boot:
the chat carries a confident identity and a state it invented. **Never report an identity you
could not assemble.** Name the missing file and stop — a user fixes a named gap in seconds and
cannot fix a wrong self-image at all.

## When to use

- New chat, **no RESTART block** → use this to pick and boot an agent.
- You **were** handed a RESTART block from a prior `/crit-checkpoint` → you do not need the menu;
  the block names the agent and its state. Follow it.

## Steps

### 1 · FIND the layer — before anything else

**STOP — you are not at the repo root.** First, before any file: `git rev-parse --show-toplevel`
from the working directory must print a folder that holds `.critos/`. If it fails, or prints a
folder without one, the session was opened **above** the repo (a workspace holding several
repos) or elsewhere. Claude Code discovers a repo's `.claude/` **upward from the working
directory, never downward** — so from above it the native steward cannot be invoked, a hook in
the repo's `.claude/settings.json` is silently dead, and every control fails at once. Name the
folder you are in, say what is dead, and stop: **the remedy is to reopen Claude Code at the
repo root** — an agent that reads its way into the repo by path still boots, into a project whose
guards are off.

| What | Where |
|---|---|
| roster | `.critos/project/agents.md` |
| settings | `.critos/project/settings.md` |
| inbox | `.critos/shared/HANDOFFS.md` |
| contracts register | `.critos/shared/CONTRACTS.md` |
| roadmap | `.critos/shared/ROADMAP.md` |
| system contracts | `.critos/system/` (in the CritOS repository itself, which publishes its tier rather than installing it: `system/`) |

**STOP — no roster.** Say so, name the path, and assume no identity: a repo with no roster has no
actors to become. Then guide, do not just refuse: if the repo has never been scaffolded, say
that `/crit-scaffold-project` creates the layer and `/crit-team` then decides its agents, and
offer to start the first one now. If a roster exists but lists only the steward, the project is
scaffolded and has no team yet: point at `/crit-team`.

**STOP — the roster is not this project's.** Check that the repo root you are in is the one the
roster describes. A roster found at the expected path in the wrong repo is the most dangerous
outcome there is, because everything after it looks right.

### 2 · Only a rostered agent is bootable

**The test is the roster read in § 1, and nothing else:** an agent is bootable where the roster
lists it, and only there. Asked for anyone else — an agent of another project, a role the user
names from memory, `AGENT 0` (which is an inbox address for *upstream*, never an actor:
`contract-agent § 5`) — **refuse, then stop**: say the roster does not list it, do not search
other repos for it, assume no identity. The menu of § 3 is shown only if the user then asks for
one of this repo's agents.

### 3 · CHOOSE — present, then wait

From the roster's **Actors** table show, per agent: number · role · form · domain (one line) ·
memory folder · shelf address. Mark `native` agents **"(invoked via the Agent tool — not booted
here)"** and do **not** offer them: a native agent is a service its caller invokes, and booting
it as a chat skips the very protocol it exists to run. Every `session` agent is pickable — the
rostered ones, and nothing else (§ 2).

**Wait for the pick.** Do not presume, and do not pick "the obvious one": the user opened a chat
with no restart block precisely because the choice was not implied.

### 4 · BOOT — the order is `contract-session.md § 1`, not a list kept here

Read it there and follow it. Eight steps — *the school · the company · yourself · the others ·
what you may never break · what you have · what is owed · where you left off* — deliberately not
restated here, because a copy of a boot order drifts from the contract that owns it.

Two things specific to running it from this skill:

- **Step 3 is your own definition.** Resolve it from the roster's **Definition** column
  (`.critos/project/agents/agent-<N>.md`; a native agent's lives in `.claude/agents/`). **If the
  roster names a definition that is not there, STOP** — an agent whose boundary you could not
  read is one you cannot be, and *what I do NOT do* is exactly the part with no fallback.
- **Several repos:** if `.claude/repos` exists, an `[OPEN]` addressed to you in a registered
  repo's inbox is owed exactly like one at home.

### 5 · REPORT — in role, and only what you actually read

- **Who:** *"I am AGENT `<N>` — `<role>`."* + domain + memory folder, one line.
- **Boundary:** one line from your definition's *what I do NOT do* — the edge, not the centre.
- **State:** where your domain stands, from your `STATUS`, 2-4 lines.
- **Owed:** every `[OPEN]` addressed to you — at home and in every registered repo.
- **Next:** 1-3 things, forward-only, from `STATUS` + the roadmap.
- **Resolved:** the files you read, and any file you could **not** read. A boot report that hides
  a missing input is the failure this skill exists to prevent.

### 6 · RECONCILE, if the STATUS reads old

Run `/crit-status-check --me <N> <your-memory-folder> --domain <your-code-path>`. **`--domain` is
not optional in practice**: a memory folder says nothing about which code its agent owns, so
without it the git axis scopes to the memory folder. The check says `SUSPECT` when that happens —
treat it as a red, not a green.

---

From here, work as that agent. Close with `/crit-checkpoint` when you intend to resume later.
