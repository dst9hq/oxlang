# ox conformance tests (Patch 007)

Run `dune runtest` at the repository root. The rule in `tests/dune` runs
`run-tests.sh` with the just-built `main.exe`; no installed `ox` is required.

- `syntax/`: scripts that **must parse** with `ox check` (not a type checker).
- `semantics/`: scripts that **must run** and produce the corresponding `.stdout`.
- `failures/`: syntax failures and runtime failures; each must fail with a
  recognizable diagnostic. The runner checks both exit status and stderr.
- `fixtures/`: deterministic inputs, copied into the Dune action context.

`examples/` remains a collection of explanatory AoC solutions, not the source
of truth for the language's conformance tests. Future patches that modify
language semantics should add or revise at least one regression test here.

The test names reflect the working **Definition of ox**: bindings, closures,
recursive values, pattern matching, field selection, list/array operations,
explicit mutation, and sequencing. Some tests also cover ox's derived forms:
`o`, `|>`, and record punning.

The test runner intentionally verifies observable behavior only. For now,
`ox check` validates syntax; it does **not** reject unbound names, type errors,
or non-exhaustive cases statically. Those are runtime failures, and the suite
marks them as such. A later static-analysis milestone should add compiler
failure tests as its implementation becomes available.

Do not rely on an exit status alone for negative tests: check the error message,
too, so missing files and unrelated crashes cannot masquerade as success.

This is a proposed conformance suite, not an assertion that tests were run
under OxCaml. It requires building the interpreter first.
