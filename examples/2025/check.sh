#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."

if command -v dune >/dev/null 2>&1; then
  run() { dune exec ./main.exe -- "$@"; }
elif command -v ox >/dev/null 2>&1; then
  run() { ox "$@"; }
else
  echo "ox or dune is required to run these examples" >&2
  exit 127
fi

check() {
  day="$1"
  expected="$2"
  got="$(run "examples/2025/$day.ox" "examples/2025/$day.txt")"
  if [ "$got" != "$expected" ]; then
    printf 'FAIL %s\nexpected:\n%s\nactual:\n%s\n' "$day" "$expected" "$got" >&2
    exit 1
  fi
  printf 'PASS %s\n%s\n' "$day" "$got"
}

check day01 'part 1: 3
part 2: 6'
check day02 'part 1: 1227775554
part 2: 4174379265'

# `rec` works at the function site, including local recursive closures.
recursion_expected='120
13
15
16'
recursion_got="$(run examples/2025/recursion.ox)"
if [ "$recursion_got" != "$recursion_expected" ]; then
  printf 'FAIL recursion\nexpected:\n%s\nactual:\n%s\n' \n    "$recursion_expected" "$recursion_got" >&2
  exit 1
fi
printf 'PASS recursion\n%s\n' "$recursion_got"

# The old function keywords and invalid recursive RHS must not parse.
check_bad_syntax() {
  name="$1"
  code="$2"
  file="$(mktemp "${TMPDIR:-/tmp}/ox-invalid-XXXXXX.ox")"
  printf '%s\n' "$code" > "$file"
  if run check "$file" >/dev/null 2>&1; then
    printf 'FAIL %s: invalid syntax accepted\n' "$name" >&2
    rm -f "$file"
    exit 1
  fi
  rm -f "$file"
  printf 'PASS %s: syntax rejected\n' "$name"
}
check_bad_syntax old_fun 'fun f x = x'
check_bad_syntax old_fn 'val x = fn n => n'
check_bad_syntax old_val_rec 'val rec x = (n) => n'
check_bad_syntax bad_rec 'val x = rec x + 1'
