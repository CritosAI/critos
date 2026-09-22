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
| 1.0.0 | 2026-09-22 | first release | none | `none` |
