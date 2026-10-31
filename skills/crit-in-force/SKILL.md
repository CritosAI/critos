---
name: crit-in-force
description: >-
  Generate IN-FORCE.md — the law in force of an agent: one line per rule that binds it, read
  from the Carries blocks of the live entries of its two logs, grouped by lane, with the tier
  and the detector of each. The boot reads it instead of the logs whole; a log is the
  chronicle, opened at an id this file names. Use it at every round-close that touched a
  DECISIONS or LESSONS-LEARNED entry (--check tells you if it is stale), when a skill needs a
  lane's view (--lane), or to see what binds a domain right now. Generated, never hand-edited;
  it holds the rules in force only — a settled rule resolves through the atlas.
---
<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->

# crit-in-force

The law in force of one agent, derived from its logs (`contract-memory § 2`, `§ 6`).

## How to run

```
bash ~/.claude/skills/crit-in-force/in-force.sh                  # rewrite every agent's IN-FORCE.md
bash ~/.claude/skills/crit-in-force/in-force.sh --check          # fresh? exit 1 when any is stale or missing
bash ~/.claude/skills/crit-in-force/in-force.sh --lane onboarding .critos/memory/a4   # also the lane's view
```

## What it reads

Inside a live entry of `DECISIONS.md` or `LESSONS-LEARNED.md`, under a line that is exactly
`**Carries.**`, one list line per id:

```
- `<id>` · <the rule in one imperative line> · binds: <lane>[ · tier N[ — <detector>]]
- `<id>` · <the rule in one imperative line> · settled: <state>[ — <why>]
```

- An entry carries **at least its own id's line**; an entry that consolidates carries one line
  per id it absorbs — that line is the archived id's live carrier.
- `binds: <lane>` — the rule is in force; the lane is the owner's word (`code`, `onboarding/config`).
  A tier on the line wins; absent, the entry's `**Enforcement:** tier N` field; absent both, `?`.
- `settled: <state>` — the rule binds nothing: `done` · `superseded by <id>` · `consolidated in <id>`,
  then an optional ` — <why>`. Settled lines are not in the index.
- A line outside the two shapes is a `CARRIES-FORM` finding of `/crit-doc-lint [26]`.

## What it writes

`.critos/memory/a<N>/IN-FORCE.md` — a header, then one section per lane, one line per rule:
`` - `<id>` · <rule> · tier N — <detector> ``. Derived: a hand-edit disappears at the next run.
**Budget 300 lines** (`.claude/doc-lint-in-force-lines` overrides): past it `--check` prints a
`BUDGET` warning — the law in force of one agent is read at every boot, so a long index is the
signal to consolidate, not to read faster.

`--lane <prefix>` also writes `IN-FORCE.<prefix>.md`: the rules whose lane is `<prefix>` or
starts with `<prefix>/`, one section per sub-lane under a stable anchor (`#config`), so a skill
can send a reader to one phase of a procedure. A view, once present, is regenerated with the
index.

## When

- **At the round-close** that appended or changed an entry (`contract-session § 2`), beside the
  atlas. `/crit-doc-lint [27]` reports a stale or missing index.
- **At boot**, `contract-session § 1` step 8 reads it in place of the logs whole.
- Never cite it: cite the entry it points at.
