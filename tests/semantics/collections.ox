#!/usr/bin/env ox
val values = [1, 2, 3]
val doubled = L.map ((n) => n * 2) values
val selected = L.filter ((n) => n > 2) doubled
val total = L.foldl ((n, acc) => n + acc) 0 selected
val _ = P.printf "%d %d\n" (L.nth selected 0) total
