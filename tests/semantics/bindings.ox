#!/usr/bin/env ox
val x = 10
val (a, b) = (2, 3)
val _ = P.printf "%d %d\n" (x + a + b) (if x /= a then 1 else 0)
