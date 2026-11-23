#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo 'usage: run-tests.sh /path/to/ox' >&2
  exit 2
fi
ox=$1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/ox-tests.XXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
passed=0

fail() {
  printf 'FAIL %s\n' "$1" >&2
  if [ -f "$scratch/stderr" ]; then cat "$scratch/stderr" >&2; fi
  exit 1
}

check_syntax() {
  file="syntax/$1.ox"
  if ! "$ox" check "$file" >"$scratch/stdout" 2>"$scratch/stderr"; then
    fail "$file (expected syntax acceptance)"
  fi
  if ! grep -Fqx "ok: $file" "$scratch/stdout"; then
    fail "$file (unexpected check output)"
  fi
  passed=$((passed + 1))
  printf 'PASS syntax %s\n' "$1"
}

check_output() {
  name=$1
  shift
  file="semantics/$name.ox"
  if ! "$ox" "$file" "$@" >"$scratch/stdout" 2>"$scratch/stderr"; then
    fail "$file (unexpected exit status)"
  fi
  if [ -s "$scratch/stderr" ]; then
    fail "$file (unexpected stderr)"
  fi
  if ! diff -u "semantics/$name.stdout" "$scratch/stdout"; then
    fail "$file (output mismatch)"
  fi
  passed=$((passed + 1))
  printf 'PASS semantics %s\n' "$name"
}

check_failure() {
  phase=$1
  name=$2
  needle=$3
  file="failures/$name.ox"
  if [ "$phase" = check ]; then
    if "$ox" check "$file" >"$scratch/stdout" 2>"$scratch/stderr"; then
      fail "$file (invalid syntax accepted)"
    fi
  else
    if "$ox" "$file" >"$scratch/stdout" 2>"$scratch/stderr"; then
      fail "$file (invalid execution succeeded)"
    fi
  fi
  if ! grep -Fq "$needle" "$scratch/stderr"; then
    fail "$file (missing diagnostic: $needle)"
  fi
  passed=$((passed + 1))
  printf 'PASS failure %s\n' "$name"
}

check_syntax bindings
check_syntax functions
check_syntax records
check_syntax datatypes
check_syntax composition
check_syntax blocks
check_syntax equality
check_syntax tuple-transformations

check_output bindings
check_output records
check_output closures
check_output recursion
check_output datatypes
check_output collections
check_output composition
check_output mutation
check_output files fixtures/numbers.txt
check_output process
check_output equality
check_output tuple-transformations

check_failure check old-fun 'syntax error'
check_failure check invalid-rec 'syntax error'
check_failure check missing-semicolon 'syntax error'
check_failure check invalid-record 'syntax error'
check_failure check old-inequality 'syntax error'
check_failure check old-equality 'syntax error'
check_failure run unbound-name 'unbound name'
check_failure run division-by-zero 'division by zero'
check_failure run non-exhaustive 'non-exhaustive case expression'
check_failure run invalid-integer 'invalid integer'

printf 'PASS all %d tests\n' "$passed"
