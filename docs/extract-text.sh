#!/usr/bin/env bash
set -euo pipefail

command -v pdftotext >/dev/null || {
  printf 'pdftotext is required (macOS: brew install poppler)\n' >&2
  exit 1
}

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

while IFS= read -r -d '' pdf; do
  relative=${pdf#"$here"/}
  output="$here/text/${relative%.*}.txt"
  mkdir -p "$(dirname "$output")"
  pdftotext -layout -enc UTF-8 "$pdf" "$output"
  printf '%s -> %s\n' "$relative" "text/${relative%.*}.txt"
done < <(find "$here" -type f -iname '*.pdf' ! -path "$here/text/*" -print0)
