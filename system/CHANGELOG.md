# System tier — changelog

**An index for the migrating steward, not a narrative.** One row per release, newest first: what
the law now says, what stops conforming, what to do. Every release answers two fields:

- **Impact on existing data** — what stops conforming (a system change does not break a project's
  structure; it breaks the data already written under the previous contract).
- **Migration** — `mechanical` (the steward applies it) · `owner-routed` (the steward routes it to
  each owner) · `none`. **LOOP FIRES** marks a release that changes the steward's own definition:
  the steward applies the re-copy, ends its session, and its successor completes the remainder
  (`contract-system § 6`).

"Re-copy the tier" = the 8 files of `system/` (5 contracts + `VERSION` + `CHANGELOG.md` +
`README.md`), verified with `/crit-doc-lint [14]`.

| Version | Date | Law — what changed | Impact on existing data | Migration |
|---|---|---|---|---|
| 1.1.1 | 2026-10-21 | no change of law. The public pages' install lines name the released version (they named `v1.0.0`), and the test suite's eighth leg holds them to `system/VERSION`; the conventions guide says an example stamp is a placeholder, never a date | none — the five contracts are byte-identical to `1.1.0` | `mechanical` — re-copy the tier (only `VERSION` and `CHANGELOG.md` change); no loop, nothing to re-install |
| 1.1.0 | 2026-10-20 | **a domain has a PHYSICAL root** (`contract-agent § 1`, `§ 3`; `contract-memory § 7`): every domain's roots in the roster's `Roots` column — the steward's precompiled, the folder of a declared Shelf index a root by construction — a surface shared by nature stays a write-surface row, the map follows the ruling (the steward registers, the user rules a border); `[22]` ROOTS reads every file against them · `[23]` INBOX-ACTOR reads a live entry's sender and recipients against the roster (`contract-shared § 1`), settled entries included · **a stamp is taken from `date -u` at the moment of stamping** (`contract-system § 5`); `[24]` FUTURE-DATE reads the stamp positions — an entry's head, a token's date, an id heading, `Last updated:`, a register verdict, an aging mark — never a date in prose · a lesson may name the `contract-session § 6` bound it instantiates — `Bound:`, optional (`contract-memory § 3`), its value checked by `[11]` · the partition procedure measures where files sit and ends in roots · the atlas copies a heading as text · the test suite fails on an interpreter diagnostic in a control's output | every roster lacks the `Roots` column — `[22]` says SKIPPED, never clean, until it exists; a live inbox entry whose sender is unrostered or `AGENT 0`, or whose recipient is unrostered, is a finding; a future date in a stamp position is a finding, corrected by its owner's hand; a `Bound:` outside the eight names is a finding | `mechanical` for the column — re-copy the tier; add `Roots` to the roster's Actors table between Domain and Memory, the steward's cell as the template has it · `owner-routed` for the fill — the steward proposes each domain's roots from the tree, the user rules them, `[22]` reports until the map is whole · regenerate the atlas. No loop: the steward's definition is unchanged. Nothing to re-install: no skill added |
| 1.0.1 | 2026-10-04 | the perimeter (`contract-system § 0`): CritOS governs the builders — whoever advances the mainline, however it is invoked; a program the project runs is code owned by a domain, never an agent; what is not a builder's own work enters only as its owner's own entry | none detectable — an entry that relayed outside content as it came now reads against the membrane; no check finds it, and its owner restates it when the work next touches it | `mechanical` — re-copy the tier; the steward's definition and the controls are unchanged, nothing to re-install |
| 1.0.0 | 2026-09-22 | first release | none | `none` |
