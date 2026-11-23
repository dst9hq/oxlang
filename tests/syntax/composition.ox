#!/usr/bin/env ox
val inc = (x) => x + 1
val double = (x) => x * 2
val transform = double o inc
val _ = 3 |> inc |> double
