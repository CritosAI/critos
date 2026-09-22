#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# scaffold.sh - the MECHANICAL half of /crit-scaffold-project. Same input, same files, byte for
# byte: a scaffold is not something an agent improvises from a template.
#
#   bash scaffold.sh                          scaffold the repo you are in (its root is resolved)
#   bash scaffold.sh --resume                 continue an interrupted scaffold: only what is missing
#   bash scaffold.sh --agent-memory N "Name"  create .critos/memory/a<N>/ for a NEW agent (the steward,
#                                             after the user ruled that the agent exists)
#
# It never overwrites: a file that exists is reported as "skipped" and left alone. It never
# commits, never pushes, and writes nothing outside the repo. It says WHERE it is about to write
# before it writes, and refuses a repo that already has a layer unless --resume is given.
#
# A template becomes its instance by exactly two operations: the SCAFFOLD:BEGIN ... SCAFFOLD:END
# block leaves (with the blank lines after it), and the MECHANICAL placeholders are filled:
#   <PROJECT_NAME>  the name of the repo's root folder      (routing file, settings, roster)
#   <N> <Domain>    the agent's number and its domain name  (the memory triple)
#   <TODAY>         the UTC date; CRITOS_SCAFFOLD_DATE overrides it (the tests pin it)
# Everything else in a template - the <TODO ...> stretches included - is the instance.
set -euo pipefail

mode=scaffold; resume=0; agent_n=""; agent_domain=""
while [ $# -gt 0 ]; do
  case "$1" in
    --resume) resume=1 ;;
    --agent-memory) mode=memory; agent_n="${2:-}"; agent_domain="${3:-}"; shift 2 || true ;;
    -h|--help) sed -n '4,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "scaffold: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift || true
done

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
critos="$(git -C "$here" rev-parse --show-toplevel 2>/dev/null)" || { echo "scaffold: cannot find the CritOS checkout from $here" >&2; exit 2; }
root="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "scaffold: not inside a git repository - run 'git init' first: every control reads 'git ls-files'" >&2; exit 2; }
[ "$root" != "$critos" ] || { echo "scaffold: the target is the CritOS checkout itself - refused" >&2; exit 2; }
cd "$root"

today="${CRITOS_SCAFFOLD_DATE:-$(date -u +%F)}"
project="$(basename "$root")"
release="$(git -C "$critos" describe --tags 2>/dev/null || echo "untagged")"
remote="$(git remote get-url origin 2>/dev/null || echo "(no remote)")"

echo "### crit-scaffold"
echo "target   $root"
echo "remote   $remote"
echo "release  $release  (system $(grep -oE '"system"[^,]*' "$critos/system/VERSION" | grep -oE '[0-9][^"]*' | head -1))"
case "$release" in *-[0-9]*-g*|untagged) echo "WARNING  the CritOS checkout is NOT on a release tag: you are pinning an unreleased revision" ;; esac

created=0; skipped=0
put() {   # $1 = source file, $2 = destination (relative to the repo root) ; a verbatim copy
  if [ -e "$2" ]; then echo "skipped  $2"; skipped=$((skipped+1)); return; fi
  mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "created  $2"; created=$((created+1))
}
instantiate() {   # $1 = template, $2 = destination, then NAME=VALUE pairs for the mechanical placeholders
  local tmpl="$1" dst="$2"; shift 2
  if [ -e "$dst" ]; then echo "skipped  $dst"; skipped=$((skipped+1)); return; fi
  mkdir -p "$(dirname "$dst")"
  # 1. the SCAFFOLD block leaves, with the blank lines after it; 2. CRLF never reaches the instance
  awk 'BEGIN{s=0} { sub(/\r$/,"") }
       s==0 && /SCAFFOLD:BEGIN/ { s=1 }
       s==1 { if (/SCAFFOLD:END/) s=2; next }
       s==2 { if ($0 ~ /^[[:space:]]*$/) next; s=3 }
       { print }' "$tmpl" > "$dst.tmp"
  grep -q 'SCAFFOLD:' "$dst.tmp" && { echo "scaffold: $tmpl has a malformed SCAFFOLD block" >&2; rm -f "$dst.tmp"; exit 2; }
  local kv name value
  for kv in "$@"; do
    name="${kv%%=*}"; value="${kv#*=}"
    value="${value//\\/\\\\}"; value="${value//&/\\&}"; value="${value//|/\\|}"
    sed -i "s|<${name}>|${value}|g" "$dst.tmp"
  done
  # the instance is LF whatever the platform's tools wrote: one byte sequence per input, everywhere
  tr -d '\015' < "$dst.tmp" > "$dst.lf" && mv "$dst.lf" "$dst" && rm -f "$dst.tmp"
  echo "created  $dst"; created=$((created+1))
}

if [ "$mode" = memory ]; then
  case "$agent_n" in ''|*[!0-9]*) echo "scaffold: --agent-memory needs the agent's NUMBER and its domain name" >&2; exit 2 ;; esac
  [ -n "$agent_domain" ] || { echo "scaffold: --agent-memory needs the domain's name, e.g. --agent-memory 2 \"Billing\"" >&2; exit 2; }
  [ -d .critos ] || { echo "scaffold: this repo has no CritOS layer yet - scaffold it first" >&2; exit 2; }
  for f in STATUS DECISIONS LESSONS-LEARNED; do
    instantiate "$critos/templates/memory-$f.md.tmpl" ".critos/memory/a$agent_n/$f.md" "N=$agent_n" "Domain=$agent_domain" "TODAY=$today"
  done
  echo "done     $created created, $skipped skipped - the roster row and the definition are the steward's, on the user's yes"
  exit 0
fi

if [ -d .critos ] && [ "$resume" = 0 ]; then
  echo "REFUSED  this repo ALREADY has a CritOS layer (.critos/). Nothing was written."
  echo "         If a scaffold was interrupted, run it again with --resume: it creates only what is missing."
  echo "         If you meant ANOTHER repo, you are in the wrong folder: see 'target' above."
  exit 3
fi

# the system tier: the whole folder, verbatim - and the steward's definition
for f in "$critos"/system/*; do put "$f" ".critos/system/$(basename "$f")"; done
put "$critos/agents/agent-1.md" ".claude/agents/agent-1.md"
# the project tier
instantiate "$critos/templates/settings.md.tmpl" ".critos/project/settings.md" "PROJECT_NAME=$project"
instantiate "$critos/templates/agents.md.tmpl"   ".critos/project/agents.md"   "PROJECT_NAME=$project"
# the work tier: the steward's memory, the three registers
for f in STATUS DECISIONS LESSONS-LEARNED; do
  instantiate "$critos/templates/memory-$f.md.tmpl" ".critos/memory/a1/$f.md" "N=1" "Domain=Steward" "TODAY=$today"
done
for f in HANDOFFS ROADMAP CONTRACTS; do instantiate "$critos/templates/$f.md.tmpl" ".critos/shared/$f.md"; done
# the routing file, then the atlas it links - generated last, so the link resolves from the first commit
instantiate "$critos/templates/CLAUDE.project.md.tmpl" "CLAUDE.md" "PROJECT_NAME=$project"
if [ ! -e MEMORY-INDEX.md ]; then
  bash "$critos/skills/crit-memory-index/memory-index.sh" >/dev/null 2>&1 && { echo "created  MEMORY-INDEX.md  (generated)"; created=$((created+1)); } \
    || echo "WARNING  the atlas could not be generated: run /crit-memory-index"
else echo "skipped  MEMORY-INDEX.md"; skipped=$((skipped+1)); fi

echo "done     $created created, $skipped skipped - nothing committed: review, then commit"
