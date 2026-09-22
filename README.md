<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# CritOS

**Multi-agent governance for your repository.**

[Website](https://critos.dev) · [Install](#install) · [Guides](docs/README.md) ·
[Changelog](system/CHANGELOG.md) · [Contributing](.github/CONTRIBUTING.md) · [License](LICENSE)

[![tests](https://github.com/CritosAI/critos/actions/workflows/tests.yml/badge.svg)](https://github.com/CritosAI/critos/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/CritosAI/critos?display_name=tag)](https://github.com/CritosAI/critos/releases)
[![license](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

A coding agent is brilliant for one session. Your project lasts years. Between the two, things
get lost: the next session does not know what the last one decided, two agents overwrite each
other, work is declared done that is not, and the same question gets settled three times.

CritOS is a **development method** for people who build software with AI coding agents — and
the tools that keep it honest. It rests on an idea you already trust from working with people:
**a part of the system has an owner, the owner knows why things are the way they are, and that
knowledge is written down where the code lives.** Installed in minutes, guided from the first
step:

- **Give an agent a domain, not a role.** Not "a coder" and "a tester": an owner of the billing
  engine, an owner of the deploy surface — each with a stated boundary, *what I do NOT do*, so
  the edge of one is where the next begins. A role has nothing to remember; a domain does.
- **It keeps the memory of that domain — and knows it better the longer it owns it.** Per
  agent, one writer: what is true now, what was decided and why, what went wrong and must not
  happen again. Every session starts from there, not from zero. Plain files, in your repo,
  versioned with git: you can read, review and correct what your agent believes. And the memory
  is *managed* — a snapshot that is overwritten, logs that are aged and archived, an index that
  finds every decision — so it is still worth reading a year in.
- **Work that is handed over, never lost.** A shared inbox where a request has one owner and a
  closure criterion, and stays counted until it is closed.
- **Checks that tell you what is actually true.** Twenty-one deterministic checks: broken links
  and orphan docs, stale status, debts nobody is counting, decisions cited that no longer
  exist, a pinned rulebook that someone edited.
- **A guard.** It asks you before a `git push`, and before any git command that would sweep
  another session's uncommitted work.
- **A steward that takes you by the hand.** CritOS ships with one agent already in it. It
  interviews you, reads your repo, *measures* where the work concentrates, and proposes how to
  cut the project into domains — then it keeps the whole thing honest. It proposes; you decide.

**The team is part of the repo.** Your agents are like the modules of your codebase: each is
*defined* in the repo, keeps its *state* in the repo, and talks to the others through a declared
channel instead of reaching into their internals. They are versioned, reviewed and cloned with
the code: clone the repository on another machine and the team comes with it — who owns what,
what each one knows, what is owed.

It works with **one agent** too: you still get the memory, the checks and the guard.

## What it is — and what it is not

CritOS is a **method**, delivered as a governance layer: rules and files in your repo, checks
on your machine. It sits on top of your agent runtime — today, **Claude Code**.

- It works at **development time**: it organises the agents that *build* your software — not
  the agents your software *runs*. Nothing of CritOS ships inside what you build.
- It is **not a runtime**, not an orchestration framework and not a service: it does not run
  agents, and there is no server, no database and no account behind it. An agent is started by
  you, or invoked by another agent — which of the two is a choice you make per agent.
- It is **for software development**: everything is built on git.
- It collects **no telemetry** and keeps no list of who uses it.
- It never pushes, builds or deploys. Those stay yours, and the guard is there to keep it so.
- Its checks **flag, they never block**: every finding goes to the agent that owns the problem.

## Requirements

- **Windows** (with **Git Bash**) or **Linux**. macOS is untested in 1.0.
- **Claude Code**, git, and Node.js (the installer and two of the checks use it).

## Install

**1 · The machine, once.** On Windows:

```powershell
git clone --branch v1.0.0 https://github.com/CritosAI/critos.git C:\tools\CritOS
cd C:\tools\CritOS
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

On Linux:

```bash
git clone --branch v1.0.0 https://github.com/CritosAI/critos.git ~/tools/CritOS
cd ~/tools/CritOS
bash install.sh
```

The installer touches four things under `~/.claude`, and nothing else: one link per skill
(`skills/crit-*`), one for the guard (`hooks/critos`), **one** entry in `settings.json` that
registers the guard (a backup is written first), and **one** block in `CLAUDE.md` between CritOS
markers. `-Uninstall` / `--uninstall` removes exactly those. `-ClaudeHome <dir>` /
`--claude-home <dir>` installs into a sandbox instead.

Keep the checkout where it is: the controls run from it. Restart Claude Code afterwards.

**2 · Each repository, once.** Open Claude Code in your repo and run:

```
/crit-scaffold-project
```

It pins the rulebook into the repo, creates the skeleton and commits. Then it offers you the
steward: a short interview, a measured reading of your repo, a proposed set of agents — one is a
legitimate answer — and, once you have ruled, the drafts of their definitions for you to
approve. Say *later* and you stop at a clean commit; **`/crit-team`** brings the steward back
whenever you want — the first time, and every time the project has grown and the team should be
looked at again.

What lands in your repo:

```
your-repo/
├── CLAUDE.md                     routing: where an agent starts reading
├── .claude/agents/agent-1.md     the steward (installed — do not edit)
└── .critos/
    ├── system/                   the five contracts, PINNED at a release — nobody edits them here
    ├── project/                  YOUR choices: settings, the roster, the agents' definitions
    ├── memory/a<N>/              one folder per agent, one writer each: STATUS, DECISIONS, LESSONS-LEARNED
    └── shared/                   the inbox, the roadmap, the register of iron rules
```

## A day with it

1. `/crit-agent-onboard` — pick an agent. It boots: the contracts, its own definition and
   boundary, what the inbox says it **owes**, and only then where it left off.
2. It works — inside its domain.
3. It closes the round: a local commit, one inbox line if the work touched a neighbour's domain,
   the checks on what it changed.
4. `/crit-checkpoint` when you stop — it reconciles its status against git and the inbox, and
   hands you a restart block for the next session.
5. `/crit-status-check` whenever you ask "what is left?" — answered from the inbox and git,
   never from memory.

## Three tiers

| Tier | What it holds | Who writes it |
|---|---|---|
| **system** — `.critos/system/` | the rules that do not vary between projects | nobody, in your repo: it is pinned, and a check tells you if it drifts |
| **project** — `.critos/project/` | the choices this project made | you; the steward keeps it consistent |
| **work** — `.critos/memory/`, `.critos/shared/` | what the work produces | the agents, one writer per folder |

The rulebook is **pinned** into each repo because a rule that changes under you fails silently.
The checks are **shared** from the machine because a broken check fails loudly, for everyone, at
once — and gets fixed.

## Updating

```powershell
cd C:\tools\CritOS ; git fetch ; git checkout v1.1.0 ; .\install.ps1
```

(on Linux: `cd ~/tools/CritOS && git fetch && git checkout v1.1.0 && bash install.sh`).

The checks are new at once. Then, in each repo, tell the steward to migrate: every release
states **what stops conforming** and **how to migrate it** (`system/CHANGELOG.md`), and the
steward applies it and verifies the pin.

## Proposing a change

Three kinds, three doors — a lesson true on any project is an **issue**, a control fix is a
**pull request with its test**, a change to the rules is **never merged as is**:
[CONTRIBUTING](.github/CONTRIBUTING.md). A vulnerability goes through
[private reporting](.github/SECURITY.md), never an issue.

## Read more

- [`system/`](system/README.md) — the five contracts. Start at `contract-system.md`.
- [`agents/agent-1.md`](agents/agent-1.md) — the steward's definition, as it is installed.
- [`docs/`](docs/README.md) — the guides: [cutting a project into domains](docs/guide-domains.md),
  installation, the method and its conventions.
- [`tests/`](tests/run.sh) — one command; every check is seen firing before its zero is believed.

## License

Apache-2.0 — © 2026 Criticaldrop Entertainment s.r.l. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
