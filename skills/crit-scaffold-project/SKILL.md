---
name: crit-scaffold-project
description: >-
  Stand up the agentic layer in a repo: PIN the versioned system tier (the five contracts) into
  .critos/system/, install the A1 definition into .claude/agents/, and create the project tier
  (settings + roster) and the work tier (memory, registers) as skeletons. Use ONCE when adopting the
  method in a new repo. Every step is idempotent — what already exists is reported and left
  untouched, never overwritten — so an interrupted run is resumed by re-running it. It does NOT
  configure the project: that is a conversation with A1, which exists by the end of this skill.
  Upgrading an already-scaffolded repo to a newer system version is a MIGRATION, not a re-scaffold —
  A1's job, and a different operation.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# crit-scaffold-project

Run in the target repo's root. It produces a project that **boots** — not one that is configured.
The difference matters: the last step hands over to A1, whose whole domain is the organisation of a
project, and who is a far better author of the roster and the settings than a template with
`<TODO>`s.

> **Delivery is hybrid.** What an agent **reads** is pinned into the project: the
> contracts and A1's definition, copied and frozen. What an agent **executes** — the controls and the
> guard hook — is provided by the **machine**, junctioned at `~/.claude/` by CritOS's `install.ps1`.
> A control fails loudly; a contract fails silently, and only the silent half needs freezing.

**Idempotence is the rule, not a courtesy.** Before writing anything, note what exists. Every step
below **skips** an existing target and says so in the report. Nothing here overwrites — the one
operation allowed to replace a pinned file is a migration, and it is not this skill.

## Steps

1. **CHECK.** You are at a repo root: **`.git` must be present**. If it is not, stop and say so —
   every control is built on `git ls-files`, so in a non-git folder they do not fail, they return
   `(none)` on every check and print a green that means nothing.

   Check the machine half too: `~/.claude/skills/crit-doc-lint/` should exist. If it does not,
   CritOS was never installed on this machine — stop and say so: the installer is `install.ps1`
   in the CritOS checkout.

   **Find the CritOS checkout from where this skill lives** — never from the project, which keeps
   no pointer to it: this file sits at `<CritOS>/skills/crit-scaffold-project/SKILL.md`, reached
   through the machine's junction, so `<CritOS>` is two folders above it
   (`git -C ~/.claude/skills/crit-scaffold-project rev-parse --show-toplevel`). Report the release
   it is at (`git describe --tags`); if it is not at a release tag, say so before pinning.

2. **RUN THE SCAFFOLD — a script, never by hand:**

   ```
   bash ~/.claude/skills/crit-scaffold-project/scaffold.sh
   ```

   **Read its first lines before anything else: `target` and `remote` say WHERE it is about to
   write.** If that is not the repo the user meant, stop — the session was opened in the wrong
   folder. If it answers `REFUSED`, the repo already has a layer: nothing was written; say so,
   and offer `--resume` only if a scaffold of THIS repo was interrupted.

   The scaffold is **deterministic** — same input, same files, byte for byte — because a
   template an agent instantiates by hand comes out different every time. Do not write, fix up
   or "improve" any of these files yourself; if one looks wrong, that is a defect to raise, not
   to patch in the instance. What it writes:

   - **the system tier, PINNED** — `<CritOS>/system/` copied WHOLE to `.critos/system/`: the five
     contracts, `VERSION`, `CHANGELOG.md`, `README.md`. Not `releases.manifest`: it is the
     release ledger, `[14]` reads it from the CritOS checkout beside the controls. And **one**
     file into `.claude/`: the steward's definition, `.claude/agents/agent-1.md`. No `skills/`,
     no `hooks/`, no `settings.json` — they come from the machine (share what fails loudly).
     Everything here is **derived**: never edited in the project, overwritten by a migration.
   - **the project tier** — `.critos/project/settings.md` (**the user's file**: its `<TODO>`s stay,
     the team interview fills them, shown in chat first) and `.critos/project/agents.md`, the
     roster, **born with one row: the steward's**.
   - **the work tier** — the steward's memory triple and the three registers, **born empty**:
     the shape of an entry or a row is kept in each file's head, written so that no control can
     read it as data.
   - **the routing file** `CLAUDE.md`, and the generated atlas `MEMORY-INDEX.md` it links.

   Each template's head says which placeholders are MECHANICAL (the script fills them: the
   project's name, the agent's number, the date) and which belong to someone else. **A new
   agent's memory folder** is created the same way, by the steward, once the user has ruled:
   `bash ~/.claude/skills/crit-scaffold-project/scaffold.sh --agent-memory <N> "<its domain>"`.

3. **REPORT.** Relay what the script printed: the target, the release pinned (and its warning
   if the checkout is not on a release tag), what was created, what was **skipped because it
   already existed**.

4. **COMMIT, locally, then stop.** Explicit pathspecs, this message:
   `git commit -m "Scaffold the CritOS layer (system tier <version>)" -- .critos .claude/agents/agent-1.md CLAUDE.md MEMORY-INDEX.md`
   — and verify: `git status --porcelain -- .critos .claude CLAUDE.md MEMORY-INDEX.md` prints
   nothing. Never push.

5. **OFFER THE TEAM — the user's one entry point.** The repo now boots; it is not yet configured.
   Step 4's commit is DONE before this step starts: whatever happens next, the scaffold stands on
   its own and the team is separate, reversible work. Then ask, in these terms:

   > The layer is in place and committed. **Do you want to decide this project's team now?** The
   > steward will interview you briefly, read the repo, and propose which agents the project
   > needs — one agent is a legitimate answer. You decide; it drafts their definitions for your
   > approval and fills the settings and the roster with you.

   - **On a yes — continue in THIS session:** follow the procedure of `/crit-team` from its first
     step — invoke the `crit-team` skill, or read `~/.claude/skills/crit-team/SKILL.md`. No
     restart is needed for it: that procedure runs the steward as a conversation and does not
     need the native agent loaded.
   - **On a no, or a later:** stop here, and say how to come back: *run `/crit-team` whenever you
     are ready.*
   - **Either way, say once, at the very end:** *restart Claude Code before your next session, so
     that `.claude/agents/agent-1.md` is discovered and the steward can be invoked from any
     chat.* The restart serves the sessions that follow — never make it a condition of this one.

   It is an OFFER, never automatic: a user who scaffolds at the end of a day must be able to
   stop at a clean commit.

   This is not delegation for its own sake. Filling `settings.md` and the roster **is** A1's domain —
   it is the actor that will live with those choices, it knows the contracts it just received, and it
   is the one that can tell you when a proposed agent has no domain of its own. A `<TODO>` list
   handed to a human is the same work done by whoever knows least about it.

## Adding an agent (the sequence, once)

Not part of scaffolding — the project is born with **A1 only**, and every other agent exists because
the user decided it. In order:

1. **The user decides** the agent exists, and its **Form** (`native` or `session`) — that choice
   decides where its definition lives and how others reach it.
2. **Write the definition** from `agent-definition.md.tmpl`, all six fields, *including "What I do
   NOT do"*: `.critos/project/agents/agent-<N>.md` (session) or `.claude/agents/agent-<N>.md`
   (native).
3. **Add the roster row** — number, role, form, domain, memory folder, definition path.
4. **Create the memory folder** `.critos/memory/a<N>/` — `scaffold.sh --agent-memory <N> "<domain>"`, never by hand.

A1 may **propose** an agent — naming it, showing why the domain needs an owner — and must then stop.
It never mints one: the steward guards the contracts, so a steward that could create agents would be
appointing its own board.

## Boundary

Writes only into the target repo. **Never edits `~/.claude/`** — the machine half is the installer's,
and this skill neither creates nor removes a junction. Never modifies the CritOS checkout. The
system tier it pins is a **copy of a release**: a contract is never changed in a project — a
change is raised (`contract-system § 3`), released, and migrated in by A1.
