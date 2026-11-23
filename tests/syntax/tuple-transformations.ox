#!/usr/bin/env ox
val rec step = fn (current, upper, total) =>
  if current > upper then total
  else
    do
      val contribution = if current mod 2 == 0 then current else 0;
      val next_total = total + contribution;

      step (current + 1, upper, next_total)
    end
val _ = step (1, 4, 0)
