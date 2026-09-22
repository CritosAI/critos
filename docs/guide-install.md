<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Guide — installing, updating, removing

CritOS is delivered in two halves, on purpose:

| Half | What | How it arrives | It changes when |
|---|---|---|---|
| **The machine** | the toolchain — the skills (`/crit-*`) and the guard hook | links from `~/.claude` into your CritOS checkout | you check out another release |
| **The repository** | the rules — five contracts and the steward's definition | **pinned**: copied into the repo, frozen | the steward migrates the repo |

*Pin what fails silently, share what fails loudly.* A rule that changes under you gives no
error, so each repo freezes the release it runs under and a check verifies the copy. A broken
check errors at once, for everyone, so it is shared and fixed once.

**1.0 runs on Windows (with Git Bash) and on Linux.** macOS is untested. Requirements: Claude Code,
git, Node.js.

## 1 · The machine

On Windows:

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

The two installers manage the same four things and print the same lines; `install.ps1` takes
`-ClaudeHome` and `-Uninstall`, `install.sh` takes `--claude-home` and `--uninstall`.

Clone a **release tag**, not the branch: the controls run live from this checkout, and the branch
is work in progress. The installer tells you which release it is installing, and warns if the
checkout is not at one.

What it manages under `~/.claude` — and nothing else:

| It creates | Why |
|---|---|
| `skills/crit-<name>` — one link per skill (a junction on Windows, a symlink on Linux) | the folder itself stays yours; other tools keep writing there |
| `hooks/critos` — one link | the guard |
| one `PreToolUse` entry in `settings.json` (backup: `settings.json.bak-critos`) | a guard that is installed and not registered guards nothing |
| one block in `CLAUDE.md`, between CritOS markers | the always-on conventions; the rest of the file is untouched |

It is idempotent — run it again at any time. **Restart Claude Code** afterwards, so the skills
are discovered. **Do not move the checkout**: every link points into it; if you must move
it, run the installer again from the new place.

If `~/.claude/skills` or `~/.claude/hooks` is itself a link, the installer refuses: a
whole-folder link would put everything any tool writes there inside the CritOS checkout.
Remove the link (`cmd /c rmdir <path>` on Windows, `rm <path>` on Linux — both remove the link,
never its target) and run it again.

**A checkout inside a synced folder** (OneDrive, Dropbox) works, but sync clients can lock files
while git or a check is reading them. If a check fails oddly, look there first.

**Try it without touching your setup:** `.\install.ps1 -ClaudeHome C:\temp\claude-sandbox`, or
`bash install.sh --claude-home /tmp/claude-sandbox`.

## 2 · Each repository

In the repo, in Claude Code:

1. **`/crit-scaffold-project`** — pins the release into `.critos/system/`, copies the steward's
   definition into `.claude/agents/`, and creates the skeletons: settings, a roster with the
   steward in it, the steward's memory, the three shared registers, a routing `CLAUDE.md`.
   Idempotent: what exists is reported and left alone.
2. **Say yes when it offers the team** — in the same chat, the steward interviews you, reads the
   repo, and proposes which agents the project should have. You decide; it drafts their
   definitions for your approval and fills the settings and the roster with you. See
   [cutting a project into domains](guide-domains.md). Say *later* and you stop at the
   scaffold's commit; **`/crit-team`** brings the steward back whenever you are ready — and again
   later, when the project has grown and the team should be looked at.
3. **Restart Claude Code** before your next session, so the steward is discovered and can be
   invoked from any chat. (Not needed for step 2.)
4. Commit. From now on a session starts with **`/crit-agent-onboard`**.

**Open Claude Code at the repo root — never in a folder above it.** Claude Code discovers a
repo's `.claude/` upward from the working directory, not downward: from a workspace that holds
several repos, none of a repo's project settings, hooks or native agents is loaded (its own
documentation says so of additional directories: *"Claude Code does not discover most `.claude/`
configuration from these additional directories"* — checked 2026-09-22). The steward cannot be
invoked, a hook you added is silently dead, and every control stops with a message that says
so. The machine half (`~/.claude`) loads from anywhere, which is what makes the mistake quiet.
One repo, one session, opened at its root.

**A clone of your repo on a machine without CritOS** carries the rules and the memory but not
the tools: the skills and the guard are missing, and the routing `CLAUDE.md` says so. Install
the machine half there.

## 3 · Updating

```powershell
cd C:\tools\CritOS ; git fetch ; git checkout v1.1.0 ; .\install.ps1
```

(on Linux: `cd ~/tools/CritOS && git fetch && git checkout v1.1.0 && bash install.sh`).

The checks are new immediately, in every repo on the machine. The **rules** in each repo are
not: each stays pinned at the release it declares until you ask the steward to **migrate** it.
Every release states, in `system/CHANGELOG.md`, **what stops conforming** and **how it is
migrated** — mechanically by the steward, or routed to the agent that owns the data. The
migration ends with `/crit-doc-lint`: check `[14]` must find the pin intact at the new release.

A repo may stay on an older release for as long as you like: `[14]` verifies it against the
release it declares, not against the latest.

## 4 · Your own build and deploy commands

The guard covers **git**, which every repo has: it asks before a push, and before a command that
would sweep another session's uncommitted work. `contract-session § 5` also reserves builds,
deploys and remote jobs to you — but those commands belong to your stack, so CritOS does not
guess them. To have them asked about too, add a hook of your own in the repo's
`.claude/settings.json`:

```json
{ "hooks": { "PreToolUse": [ { "matcher": "Bash|PowerShell",
    "hooks": [ { "type": "command", "command": "bash .claude/hooks/ask-before-deploy.sh" } ] } ] } }
```

and let the script answer `ask` for your commands:

```bash
#!/usr/bin/env bash
cmd=$(cat)
if printf '%s' "$cmd" | grep -Eq '<your deploy command>|<your build command>'; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Build and deploy are user-driven (contract-session § 5)."}}\n'
fi
```

Register it as an iron rule in `.critos/shared/CONTRACTS.md`, with `FLAGS` as its teeth.

## 5 · Removing

```powershell
cd C:\tools\CritOS ; .\install.ps1 -Uninstall
```

(on Linux: `bash ~/tools/CritOS/install.sh --uninstall`) removes exactly what the installer created. Your repos keep their `.critos/` — the rules, the
memory and the registers are plain files and stay readable — but the skills and the guard are
gone. To remove CritOS from a repo as well, delete `.critos/`, `.claude/agents/agent-1.md` and
the CritOS section of its `CLAUDE.md`.
