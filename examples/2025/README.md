# Advent of Code 2025 — ox examples

Both solutions cover **both parts** of their day's puzzle using the public
example data, not an individual's personal puzzle input.

| Day | Puzzle | Part 1 | Part 2 |
|---|---|---:|---:|
| 01 | Secret Entrance | 3 | 6 |
| 02 | Gift Shop | 1227775554 | 4174379265 |

From the **ox project root**, with `ox` on PATH:

```sh
ox examples/2025/day01.ox examples/2025/day01.txt
ox examples/2025/day02.ox examples/2025/day02.txt
```

Or, without installing ox:

```sh
dune exec ./main.exe -- examples/2025/day01.ox examples/2025/day01.txt
dune exec ./main.exe -- examples/2025/day02.ox examples/2025/day02.txt
```

`day01.ox` uses a fold over rotations and computes clockwise/counterclockwise
zero crossings arithmetically, counting zero stops for Part 1. `day02.ox`
uses the same predicate-driven range summation for both parts: repeated
halves in Part 1 versus any repeated block in Part 2. Its straightforward
range enumeration is intended as an example; large real inputs may need
candidate generation for performance.

Run `sh examples/2025/check.sh` to compare both outputs with expected results.
If `ox` is not installed, the script uses `dune exec` when Dune is available.

Puzzle descriptions:
- https://adventofcode.com/2025/day/1
- https://adventofcode.com/2025/day/2
