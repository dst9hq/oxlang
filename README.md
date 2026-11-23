# ox — Advent Edition (0.1-dev)

A small, data-oriented scripting language with Standard ML-inspired syntax,
implemented in OxCaml, with Menhir and ocamllex.

**Planning choices:** No C FFI, classes, methods, or `switch` statement.
Bindings use `val`, functions use `fun` or `fn`, variants use `datatype`,
and branching uses SML-style `case ... of`.

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
fun sum xs = L.foldl (fn (n, acc) => n + acc) 0 xs
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

## Datatypes and cases

```sml
datatype result = Ok of int | Error of string
fun describe result =
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
tuples (`(1, 2)`), records (`{x = 1, y = 2}`), functions, recursion,
`if ... then ... else ...`, `do ... end`, constructors, and `case`.
Inside `do`, declarations are separated by `;` and the final expression
is the result: `do val x = 1; x + 2 end`.
At top level, effects are written `val _ = ...` for this initial release.

Zero-based indexing uses `L.nth xs 0` and `A.get arr 0`.
Names `L`, `A`, `S`, `P`, `U`, `I`, `T` alias their full modules.
`Path.glob`, `Process.run`, and `argv` are also available.
`T` is mutable and string-keyed; persistent hash maps are deferred.

`P.printf`/`P.sprintf` currently support `%d`, `%s`, `%f`, `%%` only.
Inequality uses Haskell-style `/=`; `<>` is not an ox operator.
No static type inference or pattern exhaustiveness analysis yet.
The `check` command currently validates syntax, not types or IO effects.
Context outputs contain symbol locations and qualified references, not
inferred function types or proven call graphs.

This repository is an initial implementation. Test the actual build
with your OxCaml toolchain before relying on it for Advent of Code.
