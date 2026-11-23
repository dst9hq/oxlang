#!/usr/bin/env ox
val factorial = rec (n) =>
  if n == 0 then 1 else n * factorial (n - 1)
val local =
  do
    val sum = rec (n, acc) =>
      if n == 0 then acc else sum (n - 1, acc + n);
    sum (4, 0)
  end
val _ = P.printf "%d %d\n" (factorial 5) local
