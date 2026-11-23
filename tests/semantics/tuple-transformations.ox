#!/usr/bin/env ox
val equal_blocks = rec (text, width, offset) =>
  if offset == S.length text then true
  else
    do
      val first = S.sub text 0 width;
      val block = S.sub text offset width;
      val matches = first == block;
      val next_offset = offset + width;

      if matches then equal_blocks (text, width, next_offset)
      else false
    end

val repeated = (text, width) =>
  if width <= 0 then false
  else
    do
      val length = S.length text;
      val has_pair = width * 2 <= length;
      val divides = length mod width == 0;

      if has_pair andalso divides then equal_blocks (text, width, width)
      else false
    end

val count_invalid = rec (current, upper, total) =>
  if current > upper then total
  else
    do
      val is_invalid = repeated (I.to_string current, 1);
      val contribution = if is_invalid then current else 0;
      val next_total = total + contribution;

      count_invalid (current + 1, upper, next_total)
    end

val pass = {
    pair = repeated ("1212", 2)
  , mismatch = repeated ("1221", 2)
  , zero_width = repeated ("1212", 0)
  , odd_length = repeated ("12121", 2)
  , total = count_invalid (10, 33, 0)
}

val _ = P.printf "%s %s %s %s %d\n"
  (if pass.pair then "true" else "false")
  (if pass.mismatch then "true" else "false")
  (if pass.zero_width then "true" else "false")
  (if pass.odd_length then "true" else "false")
  pass.total
