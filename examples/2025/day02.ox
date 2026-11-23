#!/usr/bin/env ox

datatype range = Between of int * int
datatype rule = Twice | AnyRepeat

val parse_range = fn text =>
  do
    val bounds = S.split "-" text;
    val lower = I.parse (L.nth bounds 0);
    val upper = I.parse (L.nth bounds 1);

    Between (lower, upper)
  end

val rec equal_blocks = fn (text, width, offset) =>
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

val repeated = fn (text, width) =>
  if width <= 0 then false
  else
    do
      val length = S.length text;
      val has_pair = width * 2 <= length;
      val divides = length mod width == 0;

      if has_pair andalso divides then equal_blocks (text, width, width)
      else false
    end

val rec any_width = fn (text, width) =>
  if width * 2 > S.length text then false
  else
    do
      val matches = repeated (text, width);
      val next_width = width + 1;

      if matches then true
      else any_width (text, next_width)
    end

val invalid = fn (rule, id) =>
  do
    val text = I.to_string id;
    val length = S.length text;
    val half = length div 2;

    case rule of
        Twice =>
          if length mod 2 == 0 then repeated (text, half)
          else false
      | AnyRepeat => any_width (text, 1)
  end

val rec count_invalid = fn (rule, current, upper, total) =>
  if current > upper then total
  else
    do
      val is_invalid = invalid (rule, current);
      val contribution = if is_invalid then current else 0;
      val next_total = total + contribution;

      count_invalid (rule, current + 1, upper, next_total)
    end

val score_range = fn (rule, interval) =>
  case interval of
      Between (lower, upper) => count_invalid (rule, lower, upper, 0)

val score = fn (rule, ranges) =>
  do
    val add_range = fn (interval, total) =>
      do
        val contribution = score_range (rule, interval);
        total + contribution
      end;

    L.foldl add_range 0 ranges
  end

val input = U.read (L.hd argv)
val ranges = input |> S.trim |> S.split "," |> L.map parse_range
val part1 = score (Twice, ranges)
val part2 = score (AnyRepeat, ranges)
val answer = {part1, part2}

val _ = P.printf "part 1: %d\n" answer.part1
val _ = P.printf "part 2: %d\n" answer.part2
