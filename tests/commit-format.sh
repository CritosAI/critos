#!/usr/bin/env bash
# Copyright 2026 Criticaldrop Entertainment s.r.l.
# SPDX-License-Identifier: Apache-2.0
# The public commit format: every subject on main is `type(scope): subject`, within 72
# characters, the type from a closed set; the version commit is `release: X.Y.Z[-rc.N]`.
#     bash tests/commit-format.sh                                  the selftest, run by tests/run.sh
#     git log --no-merges --format=%s A..B | bash tests/commit-format.sh --check
# Bound, declared: this reads the SUBJECT LINE, and only its SHAPE. Whether a subject is
# imperative, and what a message must not SAY, are not patterns - a reader judges them.
set -uo pipefail

types='feat|fix|docs|test|ci|chore|refactor|release'

verdict() {   # $1 = subject ; prints "ok", or the reason it is refused, and returns 1
  local s="$1"
  if [ -z "$s" ]; then echo "the subject is empty"; return 1; fi
  if [ "${#s}" -gt 72 ]; then echo "longer than 72 characters (${#s})"; return 1; fi
  case "$s" in
    release*)
      if printf '%s' "$s" | grep -qE '^release: [0-9]+\.[0-9]+\.[0-9]+(-rc\.[0-9]+)?$'; then
        echo ok; return 0
      fi
      echo "a release subject is 'release: X.Y.Z' or 'release: X.Y.Z-rc.N', nothing else"; return 1 ;;
  esac
  if ! printf '%s' "$s" | grep -qE "^($types)(\([a-z0-9][a-z0-9.-]*\))?: [^ ]"; then
    echo "not 'type(scope): subject' with the type one of: ${types//|/ }"; return 1
  fi
  echo ok
}

# --check : read real subjects, one per line, on stdin.
if [ "${1:-}" = "--check" ]; then
  fail=0; n=0
  while IFS= read -r s; do
    [ -z "$s" ] && continue
    n=$((n + 1))
    if ! why="$(verdict "$s")"; then
      echo "COMMIT-FORMAT  $s"
      echo "               ^ $why"
      fail=1
    fi
  done
  if [ "$n" = 0 ]; then echo "ok    commit-format (no subject to read)"; exit 0; fi
  [ "$fail" = 0 ] && echo "ok    commit-format ($n subjects)"
  exit $fail
fi

# The selftest: every rule of the format, in both directions. A checker whose zero was never
# watched go red is not evidence - the refused cases below are that red, kept.
cases=(
  "ok|feat(system): a contract gains a section"
  "ok|fix(controls): the one-digit parser reads two digits"
  "ok|docs(readme): the page that sells it"
  "ok|test(scaffold): a newborn project is read as clean"
  "ok|ci(tests): the commit format is read on every pull request"
  "ok|chore(repo): the ignore list gains the local audit names"
  "ok|refactor(skills): the battery shares its finding printer"
  "ok|docs: the guide says where a session is opened"
  "ok|release: 1.0.1"
  "ok|release: 1.1.0-rc.2"
  "refused|installer: rewrite the installer"
  "refused|README: the page that sells it"
  "refused|system: a contract gains a section"
  "refused|Fix(controls): the parser reads two digits"
  "refused|feat(System): a contract gains a section"
  "refused|feat(system) a contract gains a section"
  "refused|feat(system):a contract gains a section"
  "refused|feat(system): "
  "refused|release: 1.0"
  "refused|release: the second release"
  "refused|release(system): 1.0.1"
  "refused|"
)
# The length boundary, computed rather than counted by hand: the prefix is 14 characters.
edge="feat(system): $(printf 'x%.0s' $(seq 1 58))"
cases+=("ok|$edge")
cases+=("refused|${edge}x")

fail=0; n=0
for c in "${cases[@]}"; do
  want="${c%%|*}"; s="${c#*|}"
  n=$((n + 1))
  got=ok; why="$(verdict "$s")" || got=refused
  [ "$got" = "$want" ] && continue
  echo "FAIL  commit-format  expected $want, got $got: [$s]"
  [ "$got" = refused ] && echo "        $why"
  fail=1
done
[ "$fail" = 0 ] && echo "ok    commit-format ($n cases: the shape, the type set, the release form, 72)"
exit $fail
