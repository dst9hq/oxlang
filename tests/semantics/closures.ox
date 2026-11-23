#!/usr/bin/env ox
val add = fn increment => fn n => increment + n
val plus7 = add 7
val _ = P.printf "%d\n" (plus7 5)
