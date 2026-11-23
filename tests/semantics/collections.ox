#!/usr/bin/env ox
val values = [1, 2, 3]
val doubled = L.map (fn n => n * 2) values
val selected = L.filter (fn n => n > 2) doubled
val total = L.foldl (fn (n, acc) => n + acc) 0 selected
val _ = P.printf "%d %d\n" (L.nth selected 0) total
