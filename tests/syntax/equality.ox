#!/usr/bin/env ox
val a = 3
val b = 3
val record = { value = a }
val same = a == b
val different = a /= 4
val _ = if record.value == b then 1 else 0
