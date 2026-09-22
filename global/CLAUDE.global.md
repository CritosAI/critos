# Global agentic conventions (merged into `~/.claude/CLAUDE.md`)

Always-on, project-agnostic invariants. Thin by design: the RULES live in the versioned system tier
each project carries (`.critos/system/` — five contracts, installed and pinned), not here. This
block states only what must hold before any project is opened, then points. A project's own
`CLAUDE.md` SPECIALIZES/OVERRIDES these; project rules win.

## Core invariants (normative text → the project's `.critos/system/` contracts)
**English-only** committed artifacts · **UTC** everywhere (local only for display) · **absolute dates** ·
**one source of truth** (link don't copy; in code reference a decision by stable ID / concept name, never
a hardcoded doc path) · **no floating doc** (register every new artifact in its index).

## AI ↔ user
- **STOP at the local commit.** `git push`, cloud builds, deploys, and real DB/heavy runs are user-driven
  — even when a request sounds like it implies the remote action. Dry-runs are fine.
- Propose don't presume; everything registered; least-privilege.

## The method
- **In a project that runs CritOS** (it has `.critos/system/`): the contracts ARE the method — start at
  `contract-system.md`; a session boots per `contract-session.md § 1`.
- **Rationale and craft** — read on demand, never installed: the guides in the CritOS
  repository's `docs/` (the method in ten ideas · conventions · cutting a project into domains ·
  installing). Where a guide and a contract disagree, the contract wins.
- A universal lesson is **not memory**: it is a raise — recorded in the project's inbox by the
  steward (addressed to `AGENT 0`, the reserved address for upstream), carried to the CritOS
  maintainers by the user — there is no cross-project lesson store
  (`contract-memory § 5` · `contract-agent § 5`).

## Per project
Each project carries its own routing `CLAUDE.md`, roster (`.critos/project/agents.md`), settings
(`.critos/project/settings.md`) and agent definitions — scaffolded by `/crit-scaffold-project`, then
configured with A1. The machine provides only the toolchain: `~/.claude/skills` + `~/.claude/hooks`,
junctioned from a CritOS checkout (the delivery rule: pin what fails silently, share what fails loudly —
`contract-system § 2`).
