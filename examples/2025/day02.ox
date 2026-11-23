#!/usr/bin/env ox

fun same_blocks text width offset =
  if offset = S.length text then true
  else if S.sub text offset width = S.sub text 0 width then
    same_blocks text width (offset + width)
  else false

fun repeated text width =
  if width * 2 > S.length text then false
  else if S.length text mod width /= 0 then false
  else same_blocks text width width

fun twice number =
  do
    val text = I.to_string number;
    val digits = S.length text;
    if digits mod 2 = 0 then repeated text (digits div 2) else false
  end

fun any_width text width =
  if width * 2 > S.length text then false
  else if repeated text width then true
  else any_width text (width + 1)

fun many number = any_width (I.to_string number) 1

fun sum_interval predicate current upper total =
  if current > upper then total
  else sum_interval predicate (current + 1) upper
    (if predicate current then total + current else total)

fun parse_range text =
  do
    val bounds = S.split "-" text;
    (I.parse (L.nth bounds 0), I.parse (L.nth bounds 1))
  end

fun score predicate ranges =
  ranges
  |> L.map (fn (lower, upper) => sum_interval predicate lower upper 0)
  |> L.foldl (fn (value, total) => value + total) 0

val ranges =
  U.read (L.hd argv)
  |> S.trim
  |> S.split ","
  |> L.map parse_range

val _ = P.printf "part 1: %d\n" (score twice ranges)
val _ = P.printf "part 2: %d\n" (score many ranges)
