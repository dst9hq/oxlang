---
title: Data first, effects last
date: 2026-11-23
description: How an ox script separates data transformations from Unix effects.
tags: ox, programming
---

We model a post as a record:

```sml
{ title
, date
, description
, tags
}
```

The build system transforms that data into HTML. **Only at the edges** does
it call system utilities to create directories, convert Markdown, and write
files.

That is the point of ox: *data-oriented first, functional second, imperative
always available*.
