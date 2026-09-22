# CONTRACT — The session (v1)

An agent is **stateless between sessions**. Everything it knows, it read at boot; everything the next
one will know, it must write before leaving. This contract is that rhythm.

---

## 1 · Boot — read in this order

1. **The system contracts** (`.critos/system/`) — the operating system. They do not vary per project.
2. **`project/settings.md`** — the induction: what this project is, the user's standing directives,
   and the reading it makes mandatory.
3. **Your own definition** — identity, domain, and the boundary you must not cross. It names no
   actors and no documents: the roster resolves the one, your shelf lists the other.
4. **`project/agents.md`** — the roster: who exists, who holds the domains that border yours, who
   holds the pen on which write surface — and, per actor, the **address of its shelf**.
5. **`shared/CONTRACTS.md`** — your section: the rules you may never violate. Follow each to its
   source. The forbidden is read **before** the asked: the inbox is requests, and a request
   absorbed before its rails are loaded is how a rail gets crossed in good faith.
6. **Your domain shelf, if the roster names one** — open its index and take note of what exists
   and what discipline its documents declare. Awareness, not reading: a document is opened when
   the work touches it.
7. **`shared/HANDOFFS.md`** — **top-down, newest-first, IN FULL. Never `grep`-snippeted**: long
   single-line entries render as `[Omitted long matching line]`, so a search silently hides exactly
   the entries you must act on. Address the newest `[OPEN]` entries addressed to you **before**
   re-touching older ones.
8. **Your own memory** — `STATUS` always; `DECISIONS` if you are about to touch architecture;
   `LESSONS-LEARNED` as the lens. The inbox came first on purpose: a snapshot read before the
   debt gets believed — your `STATUS` is hearsay about what you owe, and one believed snapshot
   held a false claim for seven days.

**If the project spans more than one repo**, it declares them in `.claude/repos` (one path per line,
relative to the repo root). The reconcile then asks *what do I owe* in **every** registered repo — an
`[OPEN]` addressed to you in a satellite inbox is owed exactly like one at home — and the checks
repeat their battery per repo. **One level only**: a satellite's own registry is never followed.
Declare it from every repo an agent actually boots in, not only from the hub.

Then **skim the STATUS of the domains you border** — a change in one domain usually surfaces as a
symptom in a neighbour's.

> **The order is functional, not alphabetical:** the school · the company · yourself · the others ·
> what you may never break · what you have · what is owed · where you left off. Each step reads a
> surface with **one job**; a fact lives on the surface whose job it is, and every other surface
> links to it — a sentence repeated across two boot surfaces is drift with two addresses. And the
> order is also the order of cost — `STATUS` is bounded, the append-only logs are not.

## 2 · The per-round close

**A chunk of work is not done until it is closed out.** In order:

1. **Commit locally**, explicit pathspecs.
2. **One inbox line** if it touched another domain — substance is yours; A1 only routes.
3. **Flip the register row** if the round completed or materially changed a **roadmap item you lead**
   — yourself with proof, or a one-line proposal to A1 **as an inbox entry** (a proposal is never an
   invocation: A1 is invoked only for a bounded read-only service — an audit, a lint, an index).
   **Same round, not at checkpoint**: a landed effort whose row stays open re-litigates as "still to
   do", and the lead is the only actor who knows it landed.
4. **Run the deterministic checks** on what you changed, and **fact-flip on the spot** (§4).
5. **Refresh the generated index** if you appended an ADR or a lesson. An index nobody regenerates is
   worse than none: it looks like a map and points at the past.

## 3 · The checkpoint

Heavier, and only when winding a session down to resume later: reconcile · overwrite `STATUS` ·
append what you decided and learned · tidy and register · route ripples to the inbox · emit a
**restart block** for the next chat.

**The restart block is the propagation vector — treat it as radioactive.** It is written by one
session and *believed* by the next. Derive its "next" line from the **inbox query**, never from your
own prose, and make the fresh session **re-run the query anyway**. A snapshot composed from memory
does not merely record a stale claim: it launders it into the next agent's boot context, where it
arrives with the authority of a handoff.

## 4 · The fact-flip

**A claim of yours that the evidence disproves is corrected on the spot** — with the date and the
proof reference — not deferred to the next checkpoint.

It applies to `STATUS` and to register rows, and only to them, because they are the only surfaces
that **assert the present**. An ADR and a lesson record something that happened: they can become
irrelevant, never false.

**Never report "already fixed, my STATUS doesn't know yet" and leave the lie in the file.**

## 5 · What the agent must not do alone

These are the user's, even when a request seems to imply them:

- **`git push`** — the agent commits locally and hands off.
- **Cloud builds and deploys**, remote job execution.
- **Real or heavy runs** — full crawls, batch jobs, training, bootstraps. Dry-runs are autonomous.
- **Production writes** beyond a single-row debug update; any mass `DELETE`/`UPDATE`/`TRUNCATE`.
- **Bucket/storage creation, mass upload, mass delete.**
- **And anything else destructive, irreversible, or visible outside this machine.** The list above is
  the set that recurs, not the boundary: when in doubt on a destructive action, ask rather than guess.

*"Commit so I can see it deployed"* means **commit, then ask** — never commit + push + deploy. The
turn ends at the local commit with an explicit "ready for you to push".

**Shared worktree:** several sessions share one git index. Stage **explicit pathspecs**, and put
the pathspec **on the commit too** — `git commit -- <paths>` — because a plain `git commit` takes
the index as it finds it, a neighbour's staged work included; never `git add -A`, `git stash`,
`git commit -a`, `git checkout .`, `git clean -fd` — each is one command with a worktree-wide
effect that reaches other sessions' uncommitted work. After a `git mv`, the pathspec names
**both** paths — the new one alone leaves the old file in HEAD. And a commit is verified against
**HEAD, never the working tree**: `git status --porcelain <paths>` must print nothing for the
paths just committed — git's own `rename (100%)` line states that the content did NOT change,
which is the defect, not the reassurance.

**Shared files, same hazard through the non-git door:** rewrite a shared file **atomically** —
build the finished bytes before opening the target, write a temporary file, then replace the
original. Never hold a truncating write handle open across code that can fail: truncation happens
**at open**, so the destruction precedes the error that was supposed to prevent it, and restoring
from HEAD is lossless only when the file happens to carry no uncommitted work — a property no
session controls. And the recovery is bound the same way: before restoring a shared file from
HEAD (`git checkout HEAD -- <path>`), **prove HEAD carries what the tree had** — the pathspec
makes the command look safe, yet it overwrites every uncommitted edit to that path, a
neighbour's included. Tier 3 by nature, declared: the failing pattern lives in throwaway scripts
no lint ever sees — the rule is enforced by being read.

## 6 · Two rules that make the rest survivable

**A rule is not a control.** Every rule here sits at one of three tiers, and you should know which:
**1 impossible** (the violation cannot be expressed) · **2 detected deterministically** (a script
finds it whether or not anyone remembered) · **3 written down and hoped for**. Only 1 and 2 are
engineering. A tier-3 rule fails silently, and the failure is invisible precisely because everyone
believes the rule is in place.

**A verification is evidence only within its declared bounds.** Eight bounds, each measured in the
field:

- **TIME** — a check carries the timestamp of its **run**, not of its retelling. After any gap — a
  new session, a resumed conversation, a day boundary — **re-run it before repeating the claim**.
  Recall is not state.
- **LAYER** — a verification carries the layer it ran at, and **only the entry layer speaks for a
  client**: fixing a module and calling its function proves the module, while the client still hits
  the gate one layer up. Verify the path the client takes, never the one built for testing. (*Is it
  deployed* and *does it work* are two questions — a payload can prove the first while the status
  disproves the second.)
- **SHAPE** — a probe is evidence only for the shapes it was designed to see; a detector is only as
  wide as its shapes. Scope the claim to that width, and say what was **not** looked at.
- **TARGET** — verify against the artifact that **defines** the claim — the deployed revision, the
  database, the engine actually run — never a report of it.
- **INSTRUMENT** — a detector's zero is not evidence until the detector has **fired on a known
  positive**; a green that cannot go red is worse than no check. And a check is turned green only
  by **fixing what it measures**: widening a permission or an exemption until it passes builds, by
  hand, the green that cannot go red. And a known positive **expires**: it is evidence only for
  the definition it fired against — when the thing being **proved** moves inside the thing doing
  the **proving**, the old red stops being reproducible; after any change to the object under
  test, **re-drive the check red** or stop claiming a known positive. A guard must query a
  relation that does not already enforce what the guard checks — otherwise it is unsatisfiable by
  construction, and stays green with its gate deleted.
- **ACTION** — a detector reports a **SYMPTOM**: the finding may be true while the work its label
  implies is a **GUESS** — a zero is not evidence, and a **ONE is not a diagnosis**. A detector
  answers exactly the predicate it was built with, always narrower than the sentence its label
  reads like; acting on the label is acting on a paraphrase. The expensive case is not the wasted
  fix — it is the **true finding whose label-implied edit violates another rule**: the same
  broken link is repointed when its target moved and de-linked when its target died, and a red on
  a pinned file asks for a migration, never an edit. Read the shape, then choose the action.
- **ABSENCE** — a claim that a capability is **not available** carries the same burden of proof as
  a claim that it works, and is discharged the same way: by exercising the capability's **own
  entry point**, never by inspecting its inputs — absent input does not imply absent capability
  when the module resolves, defaults or loads on the caller's behalf. A false green wastes a
  check; a **false blocker becomes a standing fact**: written into the surfaces that assert the
  present, it gates work, and it is cheaper to believe than a green because nobody audits an
  excuse.
- **BASELINE** — when a change **replaces** a working path, *it still works* is discharged
  against the **replaced path, item by item** — never against the new path's own internal
  consistency: a guard tests the hypothesis that made you write it, and is structurally blind to
  everything else. The baseline unit is the **property** the previous work established — the
  ordering, the containment, that a control renders at all — not only the previous run's numbers.
  And a number a run computes, logs, and never compares is a **report, not a guard**: tier 2
  means acting on the signal, not emitting it.

As prose these bounds are **tier 3, declared** — no detector can know at which layer or against
which artifact a claim was proved, and none can know an agent inferred the wrong work from a true
finding; they are enforced by being read, and by the reviewer asking *which bound does this green
claim?* — and, on a finding, *which shapes could produce it, and is the expensive one actually the
one in front of me?* — and, on a blocker, *was the capability's own entry point exercised, or only
its inputs inspected?* — and, on a replacement, *which property of the old path was the new one
asked to repeat?*
