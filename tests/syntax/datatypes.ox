#!/usr/bin/env ox
datatype direction = Left of int | Right of int
val delta = (d) => case d of Left n => -n | Right n => n
val _ = delta (Left 4)
