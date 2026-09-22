<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Guide — conventions and working disciplines

The habits that keep a project legible to an agent that has never seen it. The contracts state
the ones that are law; this guide gathers the rest — adopt what fits, and write your own choices
in `.critos/project/settings.md`. Where it and a contract disagree, **the contract wins**.

## 1 · Three invariants, not negotiable

Under `.critos/` everything is **English**, every stored or compared time is **UTC**, and every
date is **absolute** (`2026-03-14`, never "yesterday") — `contract-system § 5`. They are the
format of the substrate the checks parse. Your project's own documents follow your settings.

## 2 · A file's name says what it is

| Name | What it is | Who changes it |
|---|---|---|
| `STATUS.md` · `DECISIONS.md` · `LESSONS-LEARNED.md` | an agent's memory | that agent, alone |
| `HANDOFFS.md` · `ROADMAP.md` · `CONTRACTS.md` | the shared registers | each agent its own lines; the steward curates |
| `contract-*.md` | the pinned rules | nobody, in the project |
| `guide-*.md` | a living reference: how we work | its owner |
| `plan-*.md` | a **transient** plan: start → land → *delete* | its lead |
| `design-*.md` · `analysis-*.md` | a design record or an investigation | its author |
| `audit-<date>-*.md` | a dated photograph — never updated, superseded by the next | nobody, after the day |
| `_tmp_*` | a throwaway: git-ignored, deleted before the commit | — |

**No floating document.** Every doc has a home and is **linked from its index** in the same
commit that creates it — check `[3]` finds the ones that are not. Choose the home at creation
time; "here for now" is how a pile starts. An index entry is a real markdown link, never a name
in backticks.

## 3 · Decisions and lessons

- **Ids name their owner:** `ADR-A<N>-NNN`, `L-A<N>-NNN`. Cite a decision **by id**, in docs and
  in code — never by path. Check `[21]` verifies that a cited id still resolves.
- **An ADR's minimum:** id · absolute date · status · the decision in one line · the why in one to
  three. A decision the user made in chat always earns one: it is the only kind no future
  reader can reconstruct from the code.
- **A lesson's bar:** it cost real time, or produced a wrong claim. It states the rule in one
  imperative line and its **enforcement tier** — and, at tier 3, why no detector is possible.
- **Never delete, supersede.** Mark what was replaced or completed; archive what is marked, or
  what pushes a log past its budget (`archive/`, with a pointer left behind). Nothing is archived
  unmarked.

## 4 · Commits

- One logical change per commit; an imperative subject; the body says *why*.
- **Explicit pathspecs, on the stage and on the commit** — `git commit -m "…" -- <paths>`. After
  a `git mv`, name both paths. Verify against HEAD: `git status --porcelain <paths>` prints nothing.
- Never `--no-verify`, never a force-push to a shared remote, without an explicit yes.
- The agent **stops at the local commit**.

## 5 · Keeping the tree skimmable

- Temporaries are `_tmp_`-prefixed and listed in `STATUS › Cleanup pending`; the list is drained
  at each checkpoint. Sweep `git status` before committing.
- A plan that did not land gets a header — `Status: parked (<date>) — <why>` — or is deleted.
  Never left ambiguous.
- Rewrite a shared file **atomically**: build the bytes, write a temporary file, replace the
  original. Before restoring a shared file from git, prove HEAD holds what the tree had.
- Hygiene rides every checkpoint (`/crit-doc-lint`); a deeper audit fires when the tree is
  reorganised or a log outgrows its budget — on need, never on a timer.

## 6 · Verifying — a working checklist

Short forms of the verification bounds (`contract-session § 6`), as things to do:

- **Verify on the path the consumer takes.** "I don't see it" is answered by driving the exact
  request the consumer makes, not by re-reading the source.
- **Assert only against the primary artifact** — the deployed revision, the live schema, the
  rendered output — never against a report of it: another agent's claim, an old commit message,
  a passing test.
- **Make the detector fire before you believe its zero.** Pin a known-bad fixture, or drop one
  filter and watch the known case appear.
- **Report shapes and scope, not verdicts.** "Clean for these two shapes, across these four
  endpoints" is honest; "clean" usually is not.
- **Prove a guard fires without doing the dangerous thing.** Probe a stash-guard with
  `stash list`, never a push-guard with a push.
- **A guard must hold on every exit** — every `catch`, `finally`, early `break`. When a fix does
  not take, find which branch actually ran.
- **Reproduce in the cheap environment first.** "Works locally, fails in production" looks like
  infrastructure and is more often a race.
- **Rename by scoped token, and check both directions:** the old token is gone except where
  history quotes it; docs and memory that cite it are part of the rename.
- **A signal only a human can judge should record, not alarm:** state once that a step-change
  happened, and say what the detector is blind to.

## 7 · Per-repo settings of the checks

Optional files under `.claude/`, read by `/crit-doc-lint`:

| File | Effect |
|---|---|
| `repos` | the other repos of this project, one path per line — the battery and the owed-counter cover them too |
| `doc-lint-exempt` | one regex per line: doc families found by convention (exempt from `[3]`), slugs and ids to leave alone (`[10]`, `[21]`) |
| `doc-lint-status-lines` | one integer: the `STATUS` line budget (default 200) |
| `doc-lint-log-lines` | one integer: the log budget (default 1200) |
| `doc-lint-status-headings` | extra words that mark a dated *as-of* heading |

## 8 · While a project is young

No ceremony without payoff: one agent is a fine start, a register with three rows is a fine
register, and a check that lands red on day one gets disabled — so the checks warn, and the
budgets are generous. Add structure when a signal asks for it
([the signals](guide-domains.md)), not before.
