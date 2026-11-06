#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The runner's name goes where it can own something. The battery repeats itself in every repo
# `.claude/repos` registers and passes the runner's name through — to a satellite with a memory
# layer only. One without is read as nobody's: every check whole, the repo-wide ones all there
# are, and the parent says so in one line. A satellite with a layer but not that folder is the
# exit 2 the --own validation owes (tests/readers.sh); one that has the folder reads the runner's
# scope there. Both forms of a close: the steward's daily `--own a<N> --all` and the round-close
# `--own a<N>`. (At 1.2.0-rc.4 every agent's close ended in exit 2 on a satellite with no layer,
# the hub read, the satellite not — the pilot's observation ⑪.)
# Usage:  bash tests/constellation.sh      (writes nothing outside a temporary folder)
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; repo="$(cd "$here/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
ok() { echo "ok    constellation  $1"; }
bad() { echo "FAIL  constellation  $1"; fail=1; }
bash "$here/fixture.sh" "$tmp/fx" "$repo/system" >/dev/null 2>&1 || { echo "FAIL  constellation  the fixture could not be built"; exit 1; }
lint="$repo/skills/crit-doc-lint/doc-lint.sh"

# Two satellites beside the hub, each a repository of its own: `layer` pins the tier and holds a9's
# memory folder, no a2's; `none` has no CritOS layer at all.
commit() { git add -A . >/dev/null 2>&1 && git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm "$1" >/dev/null; }
mkdir -p "$tmp/layer/.critos/memory/a9" && ( cd "$tmp/layer" && git init -q . && cp -r "$repo/system" .critos/system \
  && printf '# A satellite with a layer\n' > README.md && printf '# STATUS — A9\n\n**Last updated:** 2026-08-01\n' > .critos/memory/a9/STATUS.md \
  && commit "a satellite with a layer" ) || { echo "FAIL  constellation  the satellite with a layer could not be built"; exit 1; }
mkdir -p "$tmp/none/docs" && ( cd "$tmp/none" && git init -q . \
  && printf '# A satellite with no layer\n\nSee [the guide](docs/guide.md).\n' > README.md && printf '# Guide\n' > docs/guide.md \
  && commit "a satellite with no layer" ) || { echo "FAIL  constellation  the satellite with no layer could not be built"; exit 1; }
# The hub registers both — the one with a layer first, so the parent's exit is the last child's, the
# one with none. (The fixture's own registry names a folder inside the hub, for [14]; replaced here:
# a satellite is a repository of its own.)
printf '../layer\n../none\n' > "$tmp/fx/.claude/repos"

run() { out=$(cd "$tmp/fx" && CRITOS_AUTO_MEMORY="$tmp/fx.auto-memory" bash "$lint" "$@" 2>&1); rc=$?; }   # the battery's arguments: $out, $rc
child() { printf '%s\n' "$out" | awk -v r="$1" '/^###  constellation repo: /{p=($0 ~ "repo: " r "$")} p'; }   # one child's block
has() { printf '%s\n' "$c" | grep -q -- "$1"; }
hasF() { printf '%s\n' "$c" | grep -qF -- "$1"; }
first() { printf '%s\n' "$c" | grep -vE '^#' | head -1 | cut -c1-120; }

# the steward's daily close: --own a2 --all
run --own a2 --all
n=$(printf '%s\n' "$out" | grep -c '^### doc-lint done — 28 checks in [0-9]*s · scope: whole ·')
[ "$n" = 2 ] && ok "daily close (--own a2 --all): the hub and the satellite with no layer are read whole" || bad "daily close: $n whole done line(s), 2 expected"
c=$(child layer)
if hasF -- '--own a2 names no memory folder' && ! has '^### doc-lint done'; then ok "daily close: the satellite with a layer and no a2 folder is the validation's exit 2 — one line, no run"
else bad "daily close: the satellite with a layer and no a2 folder — $(first)"; fi
c=$(child none)
if hasF -- '--own a2 dropped' && has '^### layout: NONE' && has '^### scope: whole' && has '^### doc-lint done — 28 checks' && ! hasF 'names no memory folder'; then
  ok "daily close: the satellite with no layer is read as nobody's — the name dropped and said, every check whole"
else bad "daily close: the satellite with no layer — $(first)"; fi
[ "$rc" = 0 ] && ok "daily close: the parent exits 0 — the last child's exit, not the validation's 2" || bad "daily close: the parent exits $rc"

# the round-close: --own a9 — the satellite with a layer holds a9's folder: the runner's scope there
run --own a9
c=$(child layer)
if has "^### scope: the runner's — a9" && has "^### doc-lint done — 28 checks in [0-9]*s · scope: a9 (the runner's"; then
  ok "round-close (--own a9): the satellite with a9's folder reads the runner's scope — the name went where it can own something"
else bad "round-close: the satellite with a9's folder — $(printf '%s\n' "$c" | grep -E '^### scope|^doc-lint:' | head -1 | cut -c1-120)"; fi
c=$(child none)
if hasF -- '--own a9 dropped' && has '^### scope: whole' && has '^### doc-lint done — 28 checks' && ! hasF 'names no memory folder'; then
  ok "round-close: the satellite with no layer is read as nobody's, every check whole"
else bad "round-close: the satellite with no layer — $(first)"; fi
[ "$rc" = 0 ] && ok "round-close: the parent exits 0" || bad "round-close: the parent exits $rc"
exit $fail
