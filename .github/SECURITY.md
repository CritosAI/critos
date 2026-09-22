<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Security

CritOS runs on your machine and in your repository: a guard hook that reads the command an
agent is about to run, checks that read your files, an installer that writes under `~/.claude`.
Nothing phones home, nothing runs as a service, and nothing is collected.

**To report a vulnerability, use GitHub's private vulnerability reporting** — the *Security*
tab of this repository, *Report a vulnerability*. It reaches the maintainers privately; a
public issue does not, and the report may describe how to defeat the guard on every machine
that runs it.

What counts: a way to make the guard let a `git push` or a sweeping command through unasked ·
an installer step that writes outside what it declares · a check that executes content it was
meant to read. What does not: a rule an agent chose to break — the contracts are enforced by
being read, and say so.

Only the latest release is supported.
