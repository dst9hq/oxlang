#!/bin/sh
set -eu
root=$(CDPATH='' cd "$(dirname "$0")" && pwd)
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT HUP INT TERM
ox "$root/build.ox" "$root" "$out"
python3 - "$out" <<'PY'
import pathlib, sys, xml.etree.ElementTree as ET
out = pathlib.Path(sys.argv[1])
expected = [
    'index.html', 'archive.html', 'about.html', '404.html', 'style.css',
    'atom.xml', 'sitemap.xml', 'robots.txt',
    'posts/2026-11-20-first-post.html',
    'posts/2026-11-23-data-and-effects.html',
    'tags/ox.html', 'tags/writing.html', 'tags/programming.html',
]
for filename in expected:
    assert (out / filename).is_file(), f'missing: {filename}'
index = (out / 'index.html').read_text()
assert 'Data first, effects last' in index
assert 'The smallest useful blog' in index
assert index.index('Data first, effects last') < index.index('The smallest useful blog')
assert 'Data first, effects last' in (out / 'tags/ox.html').read_text()
assert 'Data first, effects last' not in (out / 'tags/writing.html').read_text()
atom = ET.parse(out / 'atom.xml').getroot()
ns = {'a': 'http://www.w3.org/2005/Atom'}
assert len(atom.findall('a:entry', ns)) == 2
sitemap = ET.parse(out / 'sitemap.xml').getroot()
sm = {'s': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
assert len(sitemap.findall('s:url', sm)) == 8
print('blog example: all generated pages and feeds verified')
PY
