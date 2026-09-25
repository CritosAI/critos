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
| 1.0.1-rc.1 | 2026-09-25 | the perimeter (`contract-system § 0`): CritOS governs the builders — whoever advances the mainline, however it is invoked; a program the project runs is code owned by a domain, never an agent; what is not a builder's own work enters only as its owner's own entry | none detectable — an entry that relayed outside content as it came now reads against the membrane; no check finds it, and its owner restates it when the work next touches it | `mechanical` — re-copy the tier; the steward's definition and the controls are unchanged, nothing to re-install |
| 1.0.0 | 2026-09-22 | first release | none | `none` |
