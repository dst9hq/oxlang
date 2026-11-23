# The Definition of ox

Normative working language specification by E. Alvarez and GPT-6.

- `definition-of-ox.tex`: editable LaTeX source (working definition 0.1.1).
- `definition-of-ox.pdf`: compiled reading copy.

Build with XeLaTeX and MakeIndex:

```sh
xelatex -interaction=nonstopmode definition-of-ox.tex
makeindex definition-of-ox
xelatex -interaction=nonstopmode definition-of-ox.tex
xelatex -interaction=nonstopmode definition-of-ox.tex
```

The specification records target semantics, not a guarantee that all
normative rules are implemented by the current interpreter. `ox check`
currently parses; it does not typecheck.
