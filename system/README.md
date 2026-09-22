# The system tier

The normative core of CritOS: the rules that do not vary between projects. This folder is what a
project **pins** — `/crit-scaffold-project` copies it, whole, into the repo's `.critos/system/`,
and from then on nobody writes it from inside the project.

**Read in this order.** The first three are read at every boot; the last two are opened when you
need to write.

| # | Contract | Answers |
|---|---|---|
| 1 | [`contract-system.md`](contract-system.md) | where am I · what may I touch · **where does a fact go** (the dispatch table) · what a version change means |
| 2 | [`contract-agent.md`](contract-agent.md) | who am I · who are the others · who creates an agent · native or session, and what that decides |
| 3 | [`contract-session.md`](contract-session.md) | boot order · the per-round close · the checkpoint · the fact-flip · what I must not do alone |
| 4 | [`contract-memory.md`](contract-memory.md) | how I write what is **mine**: three tenses, and only one of them can lie · how a domain changes hands |
| 5 | [`contract-shared.md`](contract-shared.md) | how I write what is **everyone's**: the three registers and their parsed shapes |

[`VERSION`](VERSION) is the migration marker · [`CHANGELOG.md`](CHANGELOG.md) records, per release,
**what it does to data already written** and how that data is migrated.

---

**A change here is an upgrade, not an edit:** it is made upstream, released as a new version, and
applied to a project by its steward. Editing these files inside a project produces a project
running an unversioned mutant of the method — and the next migration overwrites it silently.

**The pin is verified, not trusted:** `releases.manifest`, at the root of the CritOS repository,
records every release's file hashes, and `/crit-doc-lint [14]` compares a project's copy against
its **declared** version's entries — never against the latest.
