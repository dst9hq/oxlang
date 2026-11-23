#!/usr/bin/env ox
val input = U.read (L.hd argv)
val lines = S.lines input
val numbers = L.map I.parse lines
val total = L.foldl (fn (n, acc) => n + acc) 0 numbers
val _ = P.printf "%d\n" total
