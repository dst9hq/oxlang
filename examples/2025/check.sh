#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."

if command -v ox >/dev/null 2>&1; then
  run() { ox "$@"; }
elif command -v dune >/dev/null 2>&1; then
  run() { dune exec ./main.exe -- "$@"; }
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
