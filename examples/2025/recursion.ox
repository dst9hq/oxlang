#!/usr/bin/env ox

val square = fn x => x * x
val add = fn x => fn y => x + y
val rec factorial = fn n =>
  if n == 0 then 1 else n * factorial (n - 1)
val rec fibonacci = (fn n =>
  if n < 2 then n else fibonacci (n - 1) + fibonacci (n - 2))

val local_total =
  do
    val rec sum = fn (n, acc) =>
      if n == 0 then acc else sum (n - 1, acc + n);
    sum (5, 0)
  end

val _ = P.printf "%d\n" (factorial 5)
val _ = P.printf "%d\n" (fibonacci 7)
val _ = P.printf "%d\n" local_total
val _ = P.printf "%d\n" (add 7 (square 3))
