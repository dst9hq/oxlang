#!/usr/bin/env ox
val inc = (n) => n + 1
val double = (n) => n * 2
val composed = double o inc
val _ = P.printf "%d %d\n" (composed 3) (3 |> inc |> double)
