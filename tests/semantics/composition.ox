#!/usr/bin/env ox
val inc = fn n => n + 1
val double = fn n => n * 2
val composed = double o inc
val _ = P.printf "%d %d\n" (composed 3) (3 |> inc |> double)
