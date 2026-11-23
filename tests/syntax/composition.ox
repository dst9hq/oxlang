#!/usr/bin/env ox
val inc = fn x => x + 1
val double = fn x => x * 2
val transform = double o inc
val _ = 3 |> inc |> double
