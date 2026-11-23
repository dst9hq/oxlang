# ox — Advent Edition (0.1-dev)

A small, data-oriented scripting language with Standard ML-inspired syntax,
implemented in OxCaml, with Menhir and ocamllex.

**Planning choices:** No C FFI, classes, methods, or `switch` statement.
Bindings use `val`, functions use `(parameters) => body` (with `rec` at the function site),
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
val sum = (xs) => L.foldl ((n, acc) => n + acc) 0 xs
val _ = P.printf "%d\n" (sum numbers)
```

Run `ox smoke.ox`. The expected output is `15`.

## Input parsing

```sml
#!/usr/bin/env ox
val numbers = L.map I.parse (S.lines (U.read "input.txt"))
val total = L.foldl ((x, acc) => x + acc) 0 numbers
val _ = P.printf "%d\n" total
```

## Function composition and forward application (Patch 002)

`o` constructs a composed function (`f o g` means `(x) => f (g x)`).
It associates to the right. `|>` passes a value to a function; it
associates to the left and binds more loosely than other operators.
A pipe evaluates its **left-hand value first**, before evaluating its
right-hand function.

```sml
#!/usr/bin/env ox
val numbers = U.read "input.txt" |> S.lines |> L.map I.parse
val read_numbers = L.map I.parse o S.lines o U.read
val same = read_numbers "input.txt"
val total = numbers |> L.foldl ((x, acc) => x + acc) 0
val _ = P.printf "%d\n" total
```

In a pipeline, partial application is supported: `xs |> L.map f` is
`L.map f xs`. Parenthesize complex functions, e.g. `xs |> ((xs) => xs)`.

## Datatypes and cases

```sml
datatype result = Ok of int | Error of string
val describe = (result) =>
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
tuples (`(1, 2)`), records (`{x = 1, y = 2}`), arrow functions, recursion with `rec`,
`if ... then ... else ...`, `do ... end`, constructors, and `case`.
Inside `do`, every declaration ends with `;` and the final expression
is the result: `do val x = 1; x + 2 end`. The last expression does not
need a semicolon. Record fields use commas, including leading commas on
successive lines. Record punning is supported: `{x, y}` is equivalent to
`{x = x, y = y}` and constructs a new record from the variables in scope.

```sml
val advance = (state, delta) =>
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

The AoC examples use Patch 010 arrow functions and function-site `rec`.

## Patch 010: arrow functions and recursion at the function site

`val` is the sole value-binding construct. A function expression uses a
parenthesized parameter pattern and `=>`; `->` introduces additional curried
parameters. `rec` appears immediately after `=` in a *named* `val` binding.

```sml
val square = (x) => x * x
val add_tuple = (x, y) => x + y
val add = (x) -> (y) => x + y
val factorial = rec (n) =>
  if n == 0 then 1 else n * factorial (n - 1)
```

The curried function desugars to nested closures: `(x) -> (y) => e`
means `(x) => ((y) => e)`. Each function takes exactly one value;
`(x, y)` destructures one tuple value, whereas `(x) -> (y)` receives
arguments one at a time. Parentheses around each parameter pattern are
mandatory; JavaScript's unparenthesized `x => ...` is not ox syntax.

`rec` is a function-site modifier that is valid only as the direct
initializer of a named `val`; it is not a general recursive expression.
The interpreter captures a self-referential lexical environment for the
outer closure. This applies equally to curried recursive functions.

Within `do ... end`, each declaration ends in `;`, and the final expression
returns the block's result without a semicolon:

```sml
val result =
  do
    val loop = rec (n, total) =>
      if n == 0 then total else loop (n - 1, total + n);
    loop (5, 0)
  end
```

Older `fun`, `fn`, and `val rec` syntax is rejected. A plain `val f = (x) => f x`
does *not* make `f` recursive: use `val f = rec (x) => f x` instead.

Run `sh examples/2025/check.sh` for both AoC samples and the recursion
smoke test. `ox check` validates syntax, not static types or effects.

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

## Patch 009: data-first transformations and tuple arguments

Use a tuple argument when several values jointly define one operation:
`val repeated = (text, width) => ...`. Use `->` for intentional currying:
`val add = (x) -> (y) => x + y`. Prelude functions remain curried.

Compute named intermediate values in `do ... end`, terminate every local
`val` declaration with `;`, and keep the final expression free of `;`:

```sml
val count = rec (current, upper, total) =>
  if current > upper then total
  else
    do
      val contribution = if current mod 2 == 0 then current else 0;
      val next_total = total + contribution;

      count (current + 1, upper, next_total)
    end
```

The Day 2 example follows this style. See `spec/definition-of-ox.tex`
for the formal grammar and semantics, updated through Patch 010. The
seven-file implementation budget excludes tests, examples, and the spec.
