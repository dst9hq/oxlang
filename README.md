# ox — Advent Edition (0.1-dev)

A small, data-oriented scripting language with Standard ML-inspired syntax,
implemented in OxCaml, with Menhir and ocamllex.

**Planning choices:** No C FFI, classes, methods, or `switch` statement.
Bindings use `val`, functions are `fn` values (with `val rec` for recursion),
variants use `datatype`, and branching uses SML-style `case ... of`.

## Build

With an OxCaml switch containing Dune and Menhir:

```sh
opam install dune menhir
cd ox
dune build
# Or install the public executable on your PATH:
dune install
```

The project uses only seven handwritten implementation files:
`ast.ml`, `lexer.mll`, `parser.mly`, `eval.ml`, `prelude.ml`,
`context.ml`, and `main.ml`. The Dune config and this README do not
count toward the implementation limit. Generated files belong to `_build/`.

To run without installing: `dune exec ./main.exe -- script.ox`.
Once `ox` is on your PATH, use `#!/usr/bin/env ox` and `chmod +x script.ox`.

## First AoC smoke test

Create `smoke.ox`:

```sml
#!/usr/bin/env ox
val numbers = [1, 2, 3, 4, 5]
val sum = fn xs => L.foldl (fn (n, acc) => n + acc) 0 xs
val _ = P.printf "%d\n" (sum numbers)
```

Run `ox smoke.ox`. The expected output is `15`.

## Input parsing

```sml
#!/usr/bin/env ox
val numbers = L.map I.parse (S.lines (U.read "input.txt"))
val total = L.foldl (fn (x, acc) => x + acc) 0 numbers
val _ = P.printf "%d\n" total
```

## Function composition and forward application (Patch 002)

`o` constructs a composed function (`f o g` means `fn x => f (g x)`).
It associates to the right. `|>` passes a value to a function; it
associates to the left and binds more loosely than other operators.
A pipe evaluates its **left-hand value first**, before evaluating its
right-hand function.

```sml
#!/usr/bin/env ox
val numbers = U.read "input.txt" |> S.lines |> L.map I.parse
val read_numbers = L.map I.parse o S.lines o U.read
val same = read_numbers "input.txt"
val total = numbers |> L.foldl (fn (x, acc) => x + acc) 0
val _ = P.printf "%d\n" total
```

In a pipeline, partial application is supported: `xs |> L.map f` is
`L.map f xs`. Parenthesize complex functions, e.g. `xs |> (fn xs => xs)`.

## Datatypes and cases

```sml
datatype result = Ok of int | Error of string
val describe = fn result =>
  case result of
      Ok n => P.sprintf "%d" n
    | Error msg => msg
val _ = print (describe (Ok 42))
```

## Structured shell execution

```sml
val result = Process.run ["echo", "hello world"]
val _ = P.printf "%d: %s" result.status result.stdout
```

Argument vectors are lists; `Process.run` does not invoke `/bin/sh`.
Process results are records with `status`, `stdout`, and `stderr`.

## Commands

- `ox script.ox [args...]`: evaluate a script, binding extra arguments to `argv`.
- `ox check script.ox`: parse without executing effects.
- `ox context script.ox`: generate `_build/ox/<script>.<id>.json`,
  emit the same JSON to stdout, and print the cache path to stderr.

## Language subset

Integers, floats, strings, booleans, lists (`[1, 2]`), arrays (`[|1, 2|]`),
tuples (`(1, 2)`), records (`{x = 1, y = 2}`), functions, recursion through `val rec`,
`if ... then ... else ...`, `do ... end`, constructors, and `case`.
Inside `do`, every declaration ends with `;` and the final expression
is the result: `do val x = 1; x + 2 end`. The last expression does not
need a semicolon. Record fields use commas, including leading commas on
successive lines. Record punning is supported: `{x, y}` is equivalent to
`{x = x, y = y}` and constructs a new record from the variables in scope.

```sml
val advance = fn (state, delta) =>
  do
    val position = state.position + delta;
    val stops = state.stops + 1;
    { position
    , stops
    }
  end
```

At top level, effects are written `val _ = ...` for this initial release.

Zero-based indexing uses `L.nth xs 0` and `A.get arr 0`.
Names `L`, `A`, `S`, `P`, `U`, `I`, `T` alias their full modules.
`Path.glob`, `Process.run`, and `argv` are also available.
`T` is mutable and string-keyed; persistent hash maps are deferred.

`P.printf`/`P.sprintf` currently support `%d`, `%s`, `%f`, `%%` only.
Equality and inequality use `==` and `/=` in ox expressions. Single `=` remains for `val`, `datatype`, and record-field bindings; `<>` is not an ox operator.
No static type inference or pattern exhaustiveness analysis yet.
The `check` command currently validates syntax, not types or IO effects.
Context outputs contain symbol locations and qualified references, not
inferred function types or proven call graphs.

This repository is an initial implementation. Test the actual build
with your OxCaml toolchain before relying on it for Advent of Code.

## 2025 Advent of Code sample solutions

See [`examples/2025/`](examples/2025/README.md) for complete Day 1 and
Day 2 scripts, official sample inputs, expected answers for both parts,
and `check.sh`. Each script takes an input filename from `argv`.

```sh
ox examples/2025/day01.ox examples/2025/day01.txt
ox examples/2025/day02.ox examples/2025/day02.txt
sh examples/2025/check.sh
```

The AoC examples use Patch 006 `val`/`val rec` function declarations.

## Patch 006: functions are values

The `fun` keyword is removed from ox source. Use `val` and `fn` for functions;
recursive functions use `val rec` and must have a lambda initializer.
Parenthesized lambdas are permitted. Multi-argument functions are written
using tuples or nested `fn` expressions.

```sml
val square = fn x => x * x
val add = fn x => fn y => x + y
val rec factorial = fn n =>
  if n == 0 then 1 else n * factorial (n - 1)
```

Within `do ... end`, each `val` declaration (including `val rec`) must end
with `;`, and the final result expression has no semicolon.

```sml
val result =
  do
    val rec loop = fn (n, total) =>
      if n == 0 then total else loop (n - 1, total + n);
    loop (5, 0)
  end
```

`val rec x = x + 1` is a syntax error. `val f = fn x => f x` does not
create a recursive binding; use `val rec` when the body refers to `f`.

Run `sh examples/2025/check.sh` for both AoC samples and the recursion
smoke test. `ox check` parses syntax but is not yet a type checker.

## Conformance tests (Patch 007)

Run `dune runtest` to execute the independent `tests/` suite: parser
acceptance, successful evaluation, and expected syntax/runtime failures.
The suite lives outside the seven production implementation files.
See [`tests/README.md`](tests/README.md).

Every subsequent language-semantics patch must include a regression test
in `tests/`; `examples/` remains for human-readable Advent of Code solutions.

## Patch 008: equality spelling

Equality is `==`, inequality is `/=`. Single `=` remains the declaration/field
separator, for example `val x = 3`, `datatype color = Red | Blue`, and
`{x = 3}`. `if x = 3 then ...` is no longer legal; use `if x == 3 then ...`.
