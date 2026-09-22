// Copyright 2026 Criticaldrop Entertainment s.r.l.
// SPDX-License-Identifier: Apache-2.0
// inbox-audit — hygiene of the shared inbox itself (doc-lint check [5]).
//
// Three checks:
//   PING-PONG     a topic that keeps alternating between agents: the symptom of an unclear
//                 boundary or an undecided question. Another handoff will not settle it.
//   NO-DONE-WHEN  an [OPEN] with no observable closure criterion: the recipient cannot know
//                 when to flip it, so it goes stale and the work gets re-litigated.
//   MULTI-OWNER   an [OPEN] addressed to several agents: one owner, the rest are FYI.
//
// Usage: node inbox-audit.mjs <inbox> [<archive>...]
import fs from "node:fs";

const files = process.argv.slice(2).filter((f) => fs.existsSync(f));
if (!files.length) process.exit(0);

const entries = [];
for (const f of files) {
  for (const line of fs.readFileSync(f, "utf8").split(/\r?\n/)) {
    const m = line.match(/^- (\d{4}-\d{2}-\d{2}) — (AGENT \d+)[^:]*?→([^:]{0,60}?):/);
    if (!m) continue;
    const tokM = line.slice(line.indexOf(":") + 1).match(/\*\*\[([A-Z-]+)/);
    const rcpt = m[3].replace(/\([^)]*\)/g, ""); // an agent named in a parenthetical is copied, not an owner
    const ref = line.match(/\[([^\]]+)\]\s*$/);
    entries.push({
      date: m[1],
      from: m[2].replace("AGENT ", "A"),
      owners: (rcpt.match(/AGENT \d+/g) || []).map((x) => x.replace("AGENT ", "A")),
      open: !!(tokM && /^(OPEN|PARKED)/.test(tokM[1])),
      doneWhen: /done when|closed when|acceptance criterion/i.test(line),
      ref: ref ? ref[1].split(",")[0].replace(/`/g, "").trim() : null,
      line,
    });
  }
}

let found = 0;

// --- PING-PONG: entries grouped by the reference they end with; >=3 hops and >=2 reversals.
// A curated register accrues hops by construction (one curator, many agents filing rows), so for
// a register the bar is higher: a single pair of agents must be doing the bouncing.
const isRegister = (ref) => /(^|\/)(CONTRACTS|ROADMAP|HANDOFFS)(\.md)?$|\/contracts\//i.test(ref);
const byRef = {};
for (const e of entries) if (e.ref) (byRef[e.ref] ||= []).push(e);
const pong = [];
for (const [ref, es] of Object.entries(byRef)) {
  if (es.length < 3) continue;
  const ordered = es.slice().sort((a, b) => (a.date < b.date ? -1 : 1));
  const seq = ordered.map((e) => e.from);
  if (new Set(seq).size < 2) continue;
  let flips = 0;
  for (let i = 1; i < seq.length; i++) if (seq[i] !== seq[i - 1]) flips++;
  if (flips < 2) continue;
  if (isRegister(ref)) {
    const pairFlips = {};
    for (let i = 1; i < seq.length; i++) {
      if (seq[i] === seq[i - 1]) continue;
      const k = [seq[i], seq[i - 1]].sort().join("↔");
      pairFlips[k] = (pairFlips[k] || 0) + 1;
    }
    const worst = Object.entries(pairFlips).sort((a, b) => b[1] - a[1])[0];
    if (!worst || worst[1] < 3) continue;
    pong.push({ ref, hops: es.length, flips: worst[1], open: es.filter((e) => e.open).length, who: worst[0], reg: true });
    continue;
  }
  pong.push({ ref, hops: es.length, flips, open: es.filter((e) => e.open).length, who: [...new Set(seq)].join("↔") });
}
pong.sort((a, b) => b.flips - a.flips);
for (const p of pong.filter((p) => p.open > 0)) {
  console.log(`PING-PONG  ${p.ref}  —  ${p.hops} hops / ${p.flips} reversals between ${p.who}, ${p.open} still open`);
  if (p.reg) console.log(`           (a curated register: counted per AGENT PAIR, since a register accrues hops by construction)`);
  console.log(`           → It has bounced. Another handoff will not settle it: name the OWNER or take a DECISION.`);
  found++;
}

// --- NO-DONE-WHEN
for (const e of entries.filter((e) => e.open && !e.doneWhen)) {
  console.log(`NO-DONE-WHEN  ${e.date}  ${e.from} → ${e.owners.join("+") || "?"}  —  [OPEN] with no observable closure criterion`);
  console.log(`           → Add "Done when: <observable>". Without it the recipient cannot know when to flip the token, so it goes stale and the work gets re-litigated.`);
  found++;
}

// --- MULTI-OWNER
for (const e of entries.filter((e) => e.open && e.owners.length > 1)) {
  console.log(`MULTI-OWNER  ${e.date}  ${e.from} → ${e.owners.join(" / ")}  —  [OPEN] addressed to ${e.owners.length} agents`);
  console.log(`           → One owner, the rest FYI. Shared responsibility is nobody's: each assumes the other will act.`);
  found++;
}

if (!found) console.log("(none — inbox hygiene clean)");
