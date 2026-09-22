<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# CritOS — the guides

The rules are the five contracts in [`system/`](../system/README.md): short, normative, pinned
into every project. These guides are everything the contracts leave out on purpose — the
rationale, the craft, the worked method. They are **read on demand and never installed**; where a
guide and a contract disagree, **the contract wins**.

- [`guide-install.md`](guide-install.md) — installing CritOS on a machine and in a repository;
  what a clone without it carries and what it lacks; updating and uninstalling.
- [`guide-domains.md`](guide-domains.md) — cutting a project into domains: domains versus roles,
  what earns an owner, where a border goes when it is not obvious, the measurable signals that
  a partition no longer fits, and how a split or a merge is conducted.
- [`guide-method.md`](guide-method.md) — the method in ten ideas: the reasoning behind the
  contracts, short enough to read once.
- [`guide-conventions.md`](guide-conventions.md) — naming, decision records, commits, keeping the
  tree skimmable, a verification checklist, the per-repo settings of the checks.
