<!-- SPDX-License-Identifier: Apache-2.0 · Copyright 2026 Criticaldrop Entertainment s.r.l. -->
# Contributing

CritOS is a method, and a method changed without friction drifts in silence. So the three
kinds of contribution take three different doors — and only one of them is a pull request.

## A lesson that would be true on any project — open an issue

In a project that runs CritOS, a lesson that does not depend on the project's own tools,
schema or vendor is a **method amendment**: the steward records it in the project's inbox,
addressed upstream, and **you** carry it here as an issue of the kind *raise*. Say what
happened, what it cost, and which contract or control you believe should change. It is
evaluated; what is adopted ships in a release, with its migration stated — so that nobody
both writes a rule and lives under it.

## A defect in a check, the guard, the installer or a template — a pull request

A control fix arrives **with its test**: a new case in `tests/` that fails on the current
code and passes on yours. `bash tests/run.sh` must be green — every check is seen firing
before its zero is believed, and the suite is how that promise is kept. A fix without a case
is reviewed as a report, not merged as a fix. The [pull request form](PULL_REQUEST_TEMPLATE.md)
asks exactly this.

Keep the change to the control. A pull request that also edits a contract, the steward's
definition or a template's wording is split: the control part is reviewed, the rest becomes
an issue.

## A change to the rules — never merged as is

The five contracts (`system/`), the steward's definition (`agents/`) and the templates are
**law**: they are pinned into every project that adopts CritOS and read by an agent at every
boot. A pull request that changes them is closed with thanks and turned into an issue: the
change is evaluated, and if adopted it ships in a release, versioned, with its migration.

## Conventions

- Everything in the repository is **English**; dates are absolute (`2026-09-22`); time is UTC.
- A commit message says what changed and one line of why; the subject fits in 72 characters.
- A script is LF, the installer is CRLF — `.gitattributes` enforces it; do not fight it.
- Nothing here carries a story: a rule states itself and one line of why. Evidence and
  incident history stay out of the product.
