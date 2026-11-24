# ox documentation

## Language specification

Normative working language specification by E. Alvarez and GPT-6.

- `definition-of-ox.tex`: editable LaTeX source (working definition 0.1.2).
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

## Reference PDFs

Keep original reference documents (including Standard ML publications) as
PDFs under `docs/`; treat extracted text as a **search index**, not as a
replacement. Text extraction can lose mathematical layout, diagrams,
footnotes, and reading order.

Install Poppler (`brew install poppler` on macOS), then run from the repo root:

```sh
bash docs/extract-text.sh
rg -n 'recursive|function' docs/text/
```

The script mirrors `docs/**/*.pdf` into `docs/text/**/*.txt` using
`pdftotext -layout -enc UTF-8`. Generated text is ignored by Git; PDFs and
LaTeX source remain authoritative. Page breaks from `pdftotext` are retained.
Scanned/image-only PDFs need OCR before useful text extraction.
