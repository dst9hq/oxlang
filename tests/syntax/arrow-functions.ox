#!/usr/bin/env ox
val square = (x) => x * x
val add = (x) -> (y) => x + y
val triple = (x) -> (y) -> (z) => x + y + z
val multiply = (x, y) => x * y
val identity = (x) => x
val unit = () => 42
val wildcard = (_) => 9
val nested = (x) => (y) => x + y
val fact = rec (n) => if n == 0 then 1 else n * fact (n - 1)
val add_down = rec (n) -> (acc) =>
  if n == 0 then acc else add_down (n - 1) (acc + n)
val examples = [1, 2, 3] |> L.map ((x) => x * 2)
val tuple = (a, b) => {a, b}
