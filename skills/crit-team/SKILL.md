---
name: crit-team
description: >-
  The steward's guided work on a project's TEAM — which agents exist, and which DOMAIN each one
  owns. Use it (1) right after
  /crit-scaffold-project, to decide which agents the project should have — a short interview, a
  MEASURED reading of the repo, a proposed partition the user rules on; (2) at any time, to check
  whether the partition still fits — which agent has outgrown its domain, which border is in the
  wrong place, what should split or merge; (3) to conduct a split or a merge step by step. It
  proposes and conducts structure; it never decides that an agent exists and never writes a
  definition — those are the user's.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# crit-team

**This is the steward's procedure.** If you are not already the steward, read its definition
(`.claude/agents/agent-1.md`) and the contracts it cites before step 1: from here you speak as
the steward. The steward is `native`, and this procedure runs it as a conversation — legal
(`contract-agent § 2`: a native agent can also be run as a session), and necessary: an interview
needs turns.

**Before anything, check the layer exists:** `.critos/project/agents.md` and
`.claude/agents/agent-1.md`. If they do not, the repo was never scaffolded: say so, say that
`/crit-scaffold-project` creates the layer, and offer to run it. You may still measure and
propose — but nothing after the user's ruling can be written until the layer exists.

**The method** — what a domain is, where borders go, the signals — is the guide
`guide-domains.md`. The project keeps no pointer to CritOS, so find the guide from where this
skill lives: `git -C ~/.claude/skills/crit-team rev-parse --show-toplevel` prints the CritOS
checkout; the guide is `docs/guide-domains.md` under it. Read it before proposing anything; if
it cannot be found, say so and work from this file alone.

Three rules hold in every mode:

- **Measure before you speak.** Every claim about the repo in your proposal quotes a number and
  the command that produced it. An impression is not a finding. What the user TOLD you is
  evidence too, and often the decisive one — quote it as theirs (*"from you, not from git"*),
  never dressed as a measurement.
- **Propose, then stop.** The user decides that an agent exists, picks its form, and approves
  its definition (`contract-agent § 4`). You never create an agent.
- **Say what is yours and what is only the user's**, every time, at the end.

Pick the mode from what the user asked; if unclear, ask.

## Mode 1 · First setup — which agents should this project have?

1. **Interview, briefly.** Ask, and wait for the answers: what the project is and who uses it ·
   how the user works on it (alone, with how many agents at once, on which parts) · what hurts
   today (lost context, agents overwriting each other, work declared done that is not) ·
   whether there are other repos that belong to the same project · and the two facts the
   user's settings file needs and only the user has: the **display timezone**, and any
   **standing directive** that binds every agent. Ask them HERE, once — never at the end.
2. **Read the repo, measured.**
   - *What each part is* — the top-level structure, from the files themselves; from folder
     names alone if the content says nothing.
   - *Where the work has been* — file touches per area, over a long window because a first
     setup wants the whole recent history (the health check of Mode 2 uses 30 days):
     `git log --since=90.days --name-only --format= | cut -d/ -f1-2 | sort | uniq -c | sort -nr | head -20`.
     These are touches, not commits, and they include the first commit: say so when it matters.
   - *What changes together* — areas that share commits are one domain more often than two:
     `git log --since=90.days --name-only --format=@%h | awk '/^@/{if(n>1)print a; n=0; a=""; split("",s); next} NF{split($0,p,"/"); k=p[1]"/"p[2]; if(!(k in s)){s[k]=1; n++; a=a" "k}} END{if(n>1)print a}'`
     (each output line is one commit that touched more than one area).
   - *Operational surfaces* — deploy, schema, secrets and config files, and who has been
     editing them: `git log --format=%s -- <file>`. They are usually a border, not a domain.
   - *What the history cannot tell you* — a repo whose commits all sit on a few days has no
     rhythm to measure: say that the window is the whole history, and weigh it as such.
3. **Propose a partition.** As few domains as the evidence supports — **one is a legitimate
   answer**, and the honest one for a small project **worked one session at a time**. How the
   user works is an input, not a detail: a memory folder has exactly one writer
   (`contract-memory`, the invariant), so two sessions open at once are two agents — or one of
   them is writing where it must not. Propose the next free agent numbers; the user confirms
   them. For each domain: its name · what it owns,
   as a place · its border with each neighbour · why it deserves an owner (life of its own,
   decisions that accumulate) · `session` or `native`, and why. Then the things that sit ON a
   border, each assigned to one side. Quote your numbers.
4. **Wait for the ruling.** The user keeps, changes or rejects each domain.
5. **Draft, for approval.** For each agent the user approved: a definition from
   `agent-definition.md.tmpl`, all six fields, *What I do NOT do* first in your attention — the
   edge is where the neighbour begins. Present each draft; the user edits and approves; only
   then is it written.
   **`settings.md` is held to the SAME rule, more strictly — it is the USER's file**
   (`contract-system § 2`: *an agent proposes, never decides*; its named failure is an agent
   granting itself a directive). Draft what fills its `<TODO>`s — *What this project is*, the
   timezone, the directives the user gave you, a *Mandatory reading* line if a document earned
   it — **show the text in chat, and write it only on the user's yes.** Never write it first and
   ask for a read-over afterwards: a directive that is committed before it is approved is a
   directive the agent gave itself. A directive the user DICTATES in so many words is
   transcribed as dictated, dated — that is writing on his word, not deciding.
   Then: the roster rows and write-surface rows, the memory folders —
   `scaffold.sh --agent-memory <N> "<domain>"` of `/crit-scaffold-project`, never by hand — `/crit-memory-index`, `/crit-doc-lint`, one local commit.

## Mode 2 · Does the partition still fit?

1. For each rostered agent, take the signals of `guide-domains § 4` — commit share per area
   inside its domain, the shape of its `STATUS`, its logs against budget and by topic, the inbox
   traffic to and from it, the borders where it bounces. Quote each number with its command.
2. **Conclude per agent:** *keep* · *split* (which slice, along which border) · *merge* (into
   whom) · *move a border* · *add a write-surface row*. One signal is an observation; two or
   three pointing the same way are a case. Say which it is.
3. **Check the moment** (`contract-memory § 7`): is the owner in the middle of work that
   defines the domain? Then the recommendation is *after it closes*, and say what closes it.
4. Stop. The user decides.

## Mode 3 · Conducting a split or a merge

Only after the user has ruled. Tell each actor its move, in order, and do only your own.

**A split** (`contract-memory § 7`):
1. *The user* — decides the agent exists, its number and form, and approves its definition.
2. *You* — roster row, write-surface rows for the new border, the memory folder (the same
   script), the atlas; one inbox line telling every correspondent who the new addressee is.
3. *The previous owner* — hands over: one inbox entry to the new agent listing the ids of the
   domain's decisions and lessons that are still law, plus the `STATUS` section it cedes.
4. *The new agent*, first session — writes its founding block (its first ADRs consolidate that
   law, each naming the ids it consolidates) and its own `STATUS`.
5. *The previous owner* — marks the originals *superseded by* the new ids, drops the ceded
   section from its `STATUS`, archives.
6. *You* — `/crit-doc-lint`: `[21]` must find every id the founding block names; the atlas
   regenerated; one local commit per writer's round, never one for all.

**A merge** (`contract-memory § 0`): *the user* rules it · *the absorbing agent* folds the other
log's live entries into its own folder, ids untouched, and rewrites its `STATUS` · *you* retire
the roster row, move the emptied folder's files to the absorbing agent's `archive/`, regenerate
the atlas, tell the correspondents.

## Report

Close every mode the same way: what you measured · what you propose, or did · **what is yours
next, and what only the user can do**.
