#!/usr/bin/env ox

datatype turn = Left of int | Right of int

val start = {position = 50, stops = 0, passes = 0}

val parse_turn = fn line =>
  do
    val direction = S.sub line 0 1;
    val clicks = I.parse (S.sub line 1 (S.length line - 1));
    case direction of
        "R" => Right clicks
      | "L" => Left clicks
  end

val movement = fn turn =>
  case turn of
      Right clicks => clicks
    | Left clicks => -clicks

val crossings = fn (state, turn) =>
  case turn of
      Right clicks => (state.position + clicks) div 100
    | Left clicks =>
        if state.position == 0 then clicks div 100
        else if clicks >= state.position then
          1 + (clicks - state.position) div 100
        else 0

val advance = fn (state, turn) =>
  do
    val moved = (state.position + movement turn) mod 100 + 100;
    val position = moved mod 100;
    val stops = state.stops + (if position == 0 then 1 else 0);
    val passes = state.passes + crossings (state, turn);

    { position
    , stops
    , passes
    }
  end

val input = U.read (L.hd argv)
val turns = input |> S.lines |> L.map parse_turn
val final = L.foldl advance start turns
val answer = {part1 = final.stops, part2 = final.passes}

val _ = P.printf "part 1: %d\n" answer.part1
val _ = P.printf "part 2: %d\n" answer.part2
