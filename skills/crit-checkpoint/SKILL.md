---
name: crit-checkpoint
description: >-
  Close a session cleanly and emit a paste-ready RESTART BLOCK to resume in a fresh chat. Use ONLY
  when winding down a session you intend to pick up later. It reconciles (/crit-status-check), saves
  STATUS/DECISIONS/LESSONS to truth, tidies docs (/crit-doc-lint), routes cross-domain ripples to
  HANDOFFS, and re-emits your onboarding pattern
  refreshed with the current state. This is NOT the per-round close-out — that lighter rule (commit +
  HANDOFFS + /crit-doc-lint + /crit-status-check) lives in the project's .claude/CLAUDE.md § "When you finish a
  work round".
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# checkpoint

Wind a session down cleanly, so a fresh chat can resume exactly where you left off. Run it in the
**current** chat (it needs the working context to take stock and prune accurately). Do the steps in
order, then print the RESTART BLOCK.

> This restates the session contract (`.critos/system/contract-session.md § 3`) as an actionable
> checklist. If it disagrees with the contract, the contract wins. English only, like everything
> under `.critos/`.

## Steps

1. **RECONCILE — run `/crit-status-check --me <N> <your-domain>` first, and pass `--me`.** Reconcile on
   **both axes** before taking stock:
   - **vs git** — a build that shows landed is DONE, not "in flight".
   - **vs the INBOX** — every live `[OPEN]` handoff addressed to you is **owed BY you**. Read each
     one *whole*.

   ⚠️ **Do not write "blocked on others" for anything the inbox axis lists as addressed to you.**
   That sentence is only true when the inbox returns **zero** entries for you. This is not
   hypothetical: a steward once closed a session reporting its items as "blocked on others" while
   **ten** were sitting in the inbox addressed to it — one for 10 days, one already answered by an
   agent who was waiting on *it*. The false claim then rode into the next session inside the RESTART
   block this skill emits (see step 9), and survived a further boot. **The inbox outranks your
   memory of it.**

   Then in 3-6 lines: what landed this session, what's in flight, what is genuinely blocked and on
   whom. No narration of paths not taken.

2. **SAVE STATE** (your authoritative memory — see the roster's Memory map):
   - Overwrite `STATUS.md` so it reflects the REAL current state (not a diff).
   - Append any decision to `DECISIONS` and any lesson to `LESSONS-LEARNED` (with the *why*).
     Absolute dates (today).
   - If a durable CROSS-SESSION fact emerged, update auto-memory too (the fact in its own file + a
     one-line pointer in `MEMORY.md`). In-repo memory is the source of truth; auto-memory points at it.

3. **TIDY DOCS — run `/crit-doc-lint`.** Fix the broken links / path-in-code you own; route the rest to
   the owning agent via HANDOFFS. **Then refresh the memory atlas if the repo keeps one:**
   `bash ~/.claude/skills/crit-memory-index/memory-index.sh` (a checkpoint always appends to
   DECISIONS/LESSONS, so it is always owed here; `--check` proves it). Then curate (don't just
   append): prune stale/superseded entries,
   delete what's now wrong, LINK don't copy. If you changed a CONVENTION this session, write it back
   into the shared living docs in this same checkpoint. REGISTER new artifacts in their index (new
   CONTRACT → the contract register; new project doc → its folder's index; a registry-backed
   doc → sync it with its registry in the same commit; moved/renamed file → fix every inbound link).

4. **CROSS-DOMAIN RIPPLE.** If anything you did affects another domain (rename, moved file, new
   convention, dropped column, contract change), add ONE line to the inbox —
   `.critos/shared/HANDOFFS.md`, and nowhere else: a second inbox is read by nobody. Newest on top.
   Don't edit others' files beyond cross-cutting hygiene; they pull it next session. Trim HANDOFFS
   entries every bordering agent has clearly absorbed.

5. **OPEN POINTS — from the INBOX QUERY, not from recall.** Your open items are whatever step 1's
   inbox axis returned, plus what you know is genuinely in flight. **Do not compose this list from
   memory** — that is precisely how a stale "awaiting X" survives for days while X waits on you.
   Any entry the inbox flagged `*** STALE ***` is very likely **already done** and merely carrying a
   dead token: verify and flip it (`[ABSORBED … by A<N>]`) rather than re-listing it as open. An
   `[OPEN]` that is actually finished is **worse than no entry** — it re-litigates closed work.

   Shared forward work belongs on the project's ROADMAP register (`.critos/shared/ROADMAP.md`)
   — steward-driven; propose via HANDOFFS, don't
   enumerate other agents' gaps. For each pending USER action (real run, `--execute`, deploy, push)
   state it and its gate. If a change needs a MANUAL build step (e.g. a disabled/manual build
   trigger), flag it up front + name which build + the re-deploy to re-pin.

6. **A UNIVERSAL LESSON IS A METHOD PROPOSAL, not a shelf item.** If a lesson this session would be
   true on any project, it does not get filed somewhere more global — it is drafted as a change to
   the METHOD and raised with the user. Keep it in your `LESSONS-LEARNED` with its evidence in the
   meantime. There is no intermediate tier (`contract-memory § 5`).

7. **VERIFY before you commit.** Prove the change at the level it lives (`node --check` / build for
   code, the relevant test / diagnostic / DRY-RUN for behavior). State what you ran + the outcome.
   If you couldn't verify, say so plainly — never imply a check you didn't run.

8. **WORKSPACE HYGIENE.** Sweep `git status`: remove `_tmp_` / one-off probe / dump files; leave the
   tree clean. Commit finished work locally with a clear message. STOP at the local commit — push /
   deploy / infra mutations / real DB runs are user-driven, even if the task seemed to imply them.

9. **RESTART BLOCK.** Print a single fenced block to paste into a fresh chat. Keep it THIN and
   pointer-based — it rides on top of the onboarding protocol in the roster (don't duplicate it):

   ```
   RESTART — AGENT <N> — as of <YYYY-MM-DD>
   Onboarding: follow the boot order first — `.critos/system/contract-session.md § 1`
     (contracts → settings → YOUR OWN DEFINITION → roster → contracts register → your shelf →
     inbox → memory).
   FIRST ACTION, before trusting anything below:
     bash ~/.claude/skills/crit-status-check/status-check.sh --me <N> <your-memory-path> [--domain <code-path>]
     (--domain is not optional in practice: a memory folder says nothing about the code its agent owns, and without it axis 1 warns SUSPECT)
     The "Next" line below is a SNAPSHOT and may already be wrong. The inbox is authoritative.
   State: <2-4 lines — where things stand, from your STATUS.md>
   Next: <the 1-3 things to pick up — DERIVED FROM THE INBOX QUERY in step 1, not from prose>
   Pending user actions (non-blocking unless noted): <list, each with its gate>
   Watch: <any HANDOFFS line or bordering-domain change you must not undo>
   ```

   ⚠️ **The `Next:` line is the propagation vector — treat it as radioactive.** It is written by one
   session and *believed* by the next. If you compose it from your STATUS prose instead of from the
   reconciled inbox, you are not merely recording a stale claim: you are **laundering it into the next
   agent's boot context**, where it arrives with the authority of a handoff. That is exactly how a
   "blocked on others" survived two sessions while five agents waited. Derive `Next:` from step 1's
   inbox output, and make the fresh session **re-run the query anyway** — hence the FIRST ACTION line,
   which is not decoration: it is the circuit-breaker that stops a bad snapshot from outliving itself.

Confirm the working tree is clean at the end.

## Notes
- **Run in the current chat, not a fresh one** — taking stock and pruning needs the session's
  working context. The restart block is the bridge into the fresh chat.
- **Restart block stays thin on purpose** — it points at the canonical onboarding (the kickoff
  briefing) instead of repeating it, so it never goes stale. If you're pasting *facts* into it, move
  them to `STATUS.md` and link.
- **Steward specifics.** The steward (A1) also curates the inbox register (trim absorbed entries), keeps
  the shared living docs coherent across all agents' checkpoints.
- **Source of truth is the system tier + the roster.** When a rule or a memory path changes there,
  sync this checklist — never the other way around.
- **Project agents only — NOT external collaborators.** `/crit-checkpoint` writes project memory +
  `HANDOFFS`, so it applies only to an actor with a project memory home and write access. An **external
  human contributor to an agent's domain repo** (read-only on the core repo — see the roster
  § "External collaborators") **cannot use it**: they have no project memory triad, are read-only on
  memory + `HANDOFFS`, and their repo has no `.claude/` skills. Their durable state lives in their own
  repo (release notes + that repo's inbox).
