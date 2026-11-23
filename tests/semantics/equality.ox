#!/usr/bin/env ox
val left = { position = 3, stops = 1 }
val right = { stops = 1, position = 3 }
val _ = P.printf "%d %d %d\n"
  (if 4 == 4 then 1 else 0)
  (if 4 /= 5 then 1 else 0)
  (if left == right then 1 else 0)
