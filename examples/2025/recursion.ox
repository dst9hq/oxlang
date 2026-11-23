#!/usr/bin/env ox

val square = (x) => x * x
val add = (x) -> (y) => x + y
val factorial = rec (n) =>
  if n == 0 then 1 else n * factorial (n - 1)
val fibonacci = rec (n) =>
  if n < 2 then n else fibonacci (n - 1) + fibonacci (n - 2)

val local_total =
  do
    val sum = rec (n, acc) =>
      if n == 0 then acc else sum (n - 1, acc + n);
    sum (5, 0)
  end

val _ = P.printf "%d\n" (factorial 5)
val _ = P.printf "%d\n" (fibonacci 7)
val _ = P.printf "%d\n" local_total
val _ = P.printf "%d\n" (add 7 (square 3))
