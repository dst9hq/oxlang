# Advent of Code 2025 — ox, data first

Both examples solve both parts of the public sample puzzles. They illustrate
ox's intended order of design:

1. **Represent domain data.** `datatype turn` and the dial state record in
   Day 1; `datatype range` and `datatype rule` in Day 2.
2. **Define transformations.** Parsing, state transitions, and scoring are
   named functions operating on domain values. Functional combinators are
   used only where they simplify traversing collections.
3. **Orchestrate imperatively.** Read input, construct data, compute answers,
   and print the result in an explicit sequence. File I/O and output are
   effects, not disguised as pure transformations.

The examples deliberately avoid making a long `|>` chain the program's main
abstraction. `|>` remains a convenience for input conversion, not the data model.

| Day | Puzzle | Part 1 | Part 2 |
|---|---|---:|---:|
| 01 | Secret Entrance | 3 | 6 |
| 02 | Gift Shop | 1227775554 | 4174379265 |

From the ox project root, with `ox` on PATH:

```sh
ox examples/2025/day01.ox examples/2025/day01.txt
ox examples/2025/day02.ox examples/2025/day02.txt
```

Without installing ox:

```sh
dune exec ./main.exe -- examples/2025/day01.ox examples/2025/day01.txt
dune exec ./main.exe -- examples/2025/day02.ox examples/2025/day02.txt
```

Run `sh examples/2025/check.sh` to compare both outputs with expected results.
If `ox` is not installed, the script uses `dune exec` when Dune is available.

Day 1 models rotations as tagged data, and advances one dial-state record for
both parts at once. Day 2 models ranges and validation rules as data, then
scores each rule against the same ranges. The straightforward range enumeration
is intended as an example; large real inputs may require candidate generation.

Puzzle descriptions:
- https://adventofcode.com/2025/day/1
- https://adventofcode.com/2025/day/2
