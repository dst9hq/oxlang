#!/usr/bin/env ox

datatype range = Between of int * int
datatype rule = Twice | AnyRepeat

fun parse_range text =
  do
    val bounds = S.split "-" text;
    Between (I.parse (L.nth bounds 0), I.parse (L.nth bounds 1))
  end

fun equal_blocks text width offset =
  if offset = S.length text then true
  else if S.sub text offset width = S.sub text 0 width then
    equal_blocks text width (offset + width)
  else false

fun repeated text width =
  if width * 2 > S.length text then false
  else if S.length text mod width /= 0 then false
  else equal_blocks text width width

fun any_width text width =
  if width * 2 > S.length text then false
  else if repeated text width then true
  else any_width text (width + 1)

fun invalid (rule, id) =
  do
    val text = I.to_string id;
    case rule of
        Twice =>
          if S.length text mod 2 = 0 then
            repeated text (S.length text div 2)
          else false
      | AnyRepeat => any_width text 1
  end

fun count_invalid (rule, current, upper, total) =
  if current > upper then total
  else count_invalid
    (rule, current + 1, upper,
     total + (if invalid (rule, current) then current else 0))

fun score_range rule interval =
  case interval of
      Between (lower, upper) => count_invalid (rule, lower, upper, 0)

fun score rule ranges =
  L.foldl (fn (interval, total) => total + score_range rule interval) 0 ranges

val input = U.read (L.hd argv)
val ranges = input |> S.trim |> S.split "," |> L.map parse_range
val answer = {part1 = score Twice ranges, part2 = score AnyRepeat ranges}

val _ = P.printf "part 1: %d\n" answer.part1
val _ = P.printf "part 2: %d\n" answer.part2
