#!/usr/bin/env ox
val twice = fn n => n * 2
val rec factorial = (fn n => if n == 0 then 1 else n * factorial (n - 1))
val _ = twice (factorial 3)
