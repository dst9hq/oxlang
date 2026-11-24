# ox static blog generator

A complete, dependency-light example for ox Patch 010: chronological posts,
archive, tag pages, Atom 1.0 feed, sitemap, robots.txt, about page, 404 page,
and a monochrome stylesheet. Source posts are Markdown with a fixed six-line
front matter format.

## Dependencies

- `ox` if it's on your `PATH` (or use `dune exec ./main.exe --`)
- `pandoc`
- Standard `mkdir` and `cp` commands
- Optional: `python3` to preview the generated site

## Build

From the ox repository root:

```sh
ox examples/blog/build.ox examples/blog examples/blog/_site
python3 -m http.server --directory examples/blog/_site 8000
```

Run `sh examples/blog/verify.sh` to build into a temporary directory and
check output pages, tag contents, Atom entries, and sitemap XML (requires
`python3`).

Open http://localhost:8000/ to preview. Edit `site.origin` in `build.ox`
before publishing so feed and sitemap URLs use your domain.

Or run without installing `ox`:

```sh
dune exec ./main.exe -- examples/blog/build.ox examples/blog examples/blog/_site
```

## Post format

Name posts `YYYY-MM-DD-slug.md` so lexicographic sorting yields chronological
order. Slugs and tags must contain only lowercase ASCII letters, digits, and
hyphens. Use these exact first six lines, with unquoted plain-text values:

```markdown
---
title: My title
date: 2026-11-23
description: A one-sentence summary.
tags: ox, programming
---

Here begins the Markdown body.
```

The metadata parser is intentionally small: it assumes this order, enforces
simple slugs, and checks date length but does not perform full YAML or date
validation. The Markdown body is processed by Pandoc. Keep post source and
metadata trusted; `Process.run` executes tools without invoking a shell, but
Pandoc may process embedded raw HTML and external references.

## Generated output

```text
_site/
├── index.html
├── archive.html
├── about.html
├── 404.html
├── atom.xml
├── sitemap.xml
├── robots.txt
├── style.css
├── posts/
│   ├── 2026-11-20-first-post.html
│   └── 2026-11-23-data-and-effects.html
└── tags/
    ├── ox.html
    ├── programming.html
    └── writing.html
```

A build writes the current pages but does not remove previously generated
files. For a clean rebuild, delete the output directory yourself first.
The example uses absolute `/` URLs; publish it at a domain root.
