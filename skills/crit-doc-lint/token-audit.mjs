// Copyright 2026 Criticaldrop Entertainment s.r.l.
// SPDX-License-Identifier: Apache-2.0
// token-audit — lifecycle tokens outside the closed vocabulary (doc-lint check [7]).
//
// The owed-counter recognizes exactly two tokens as live, OPEN and PARKED-OWNED, and treats
// everything else as settled — so an ask written under an invented token is owed by someone,
// counted by nobody, and one rotation away from cold storage. This check names it.
// Runs on the live inbox only: archives are cold storage.
//
// Usage: node token-audit.mjs <inbox>
import fs from "node:fs";

// The closed vocabulary. Live: the recipient still owes something. Settled: a record.
const LIVE = ["OPEN", "PARKED-OWNED"];
const SETTLED = ["ABSORBED", "CLOSED", "ACK", "FYI", "SUPERSEDED", "RETRACTED"];

const file = process.argv[2];
if (!file || !fs.existsSync(file)) process.exit(0);

const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
const START = /^- (\d{4}-\d{2}-\d{2}) /;
const bad = [];
const unbolded = [];

for (const line of lines) {
  const m = START.exec(line);
  if (!m) continue;
  const colon = line.indexOf(":");
  if (colon < 0) continue;
  const rest = line.slice(colon + 1);
  // The token is read ONLY at its syntactic position — the first "[" after the colon — never
  // by searching the line: an entry may quote a token in its prose. The lead before it may be
  // decoration only (whitespace, bold markers, a parenthetical, a non-ASCII symbol), never
  // prose. The unbolded form is accepted and reported as a format defect: the owed-counter
  // counts it as live, and the two parsers must agree.
  const at = /^(?:[\s*_~]|\([^)]*\)|[^\x00-\x7F])*\[/.exec(rest);
  if (!at) continue; // no token at its position: an FYI by convention, nobody owes anything
  const bolded = /\*\*\[$/.test(at[0]);
  const p = at[0].length - 1;

  const body = rest.slice(p + 1).replace(/^[^A-Za-z]+/, "");
  const word = (body.match(/^[A-Z][A-Z-]*/) || [""])[0];
  const known = LIVE.includes(word) || SETTLED.includes(word);
  if (known && bolded) continue;
  if (known && !bolded) {
    unbolded.push({ date: m[1], token: word, gist: rest.replace(/\*/g, "").trim().slice(0, 90) });
    continue;
  }

  const participants = line.slice(0, colon);
  const arrow = participants.split("→");
  const owner = (arrow[arrow.length - 1] || "").replace(/\([^)]*\)/g, "").trim();
  bad.push({
    date: m[1],
    owner: owner || "(unparsed)",
    token: (body.split(/[\s\]]/)[0] || "(empty)").slice(0, 24),
    gist: line.slice(colon + 1).replace(/\*/g, "").trim().slice(0, 90),
  });
}

for (const u of unbolded) {
  console.log(`UNBOLDED-TOKEN  ${u.date}  token: [${u.token} …] — valid token, but not bolded (\`**[${u.token} …]\`).`);
  console.log(`                ${u.gist}…`);
  console.log(`                → Bold it: the entry grammar is load-bearing for every inbox parser.`);
}

if (!bad.length) {
  if (!unbolded.length) console.log("(none — every lifecycle token is in the closed vocabulary)");
  else console.log(`\n${unbolded.length} entr${unbolded.length === 1 ? "y" : "ies"} carry a valid but UNBOLDED token (format defect; still counted as live).`);
  process.exit(0);
}

for (const b of bad) {
  console.log(`BAD-TOKEN    ${b.date}  owner: ${b.owner}  token: [${b.token} …]`);
  console.log(`             ${b.gist}…`);
  console.log(
    `             → INVISIBLE to the owed-counter (it reads only ${LIVE.join("/")}). If this still needs`
  );
  console.log(
    `               action, retoken it "[OPEN — … Done when: <observable>]"; if it is done, "[ABSORBED <date> by An]".`
  );
}
console.log(
  `\n${bad.length} ${bad.length === 1 ? "entry carries" : "entries carry"} a token outside the closed vocabulary` +
    ` (live: ${LIVE.join(", ")} · settled: ${SETTLED.join(", ")}).`
);
