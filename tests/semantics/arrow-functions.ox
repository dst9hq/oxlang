#!/usr/bin/env ox
val square = (x) => x * x
val add = (x) -> (y) => x + y
val add7 = add 7
val add_tuple = (x, y) => x + y
val add_three = (x) -> (y) -> (z) => x + y + z
val rec_factorial = rec (n) => if n == 0 then 1 else n * rec_factorial (n - 1)
val sum_down = rec (n) -> (acc) =>
  if n == 0 then acc else sum_down (n - 1) (acc + n)
val mapped = L.map ((x) => x * 3) [1, 2, 3]
val mapped_total = L.foldl ((n, acc) => n + acc) 0 mapped
val wildcard = (_) => 19
val unit = () => 25
val pattern = (Some x) => x + 1
val _ = P.printf "%d %d %d %d %d %d %d %d\n"
  (square 4) (add7 5) (add_tuple (3, 4))
  (rec_factorial 5) (sum_down 4 0) mapped_total
  (wildcard 5) (unit ())
val _ = P.printf "%d %d\n" (pattern (Some 8)) (add_three 2 3 4)
