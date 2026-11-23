#!/usr/bin/env ox

val read_rotations = S.lines o U.read
val rotations = (L.hd argv) |> read_rotations

fun rotate (line, state) =
  do
    val direction = S.sub line 0 1;
    val clicks = I.parse (S.sub line 1 (S.length line - 1));
    val delta = if direction = "R" then clicks else -clicks;
    val position = ((state.position + delta) mod 100 + 100) mod 100;
    val passes =
      if direction = "R" then (state.position + clicks) div 100
      else if state.position = 0 then clicks div 100
      else if clicks >= state.position then
        1 + (clicks - state.position) div 100
      else 0;
    {position = position,
     stops = state.stops + (if position = 0 then 1 else 0),
     passes = state.passes + passes}
  end

val result =
  rotations |> L.foldl rotate {position = 50, stops = 0, passes = 0}

val _ = P.printf "part 1: %d\n" result.stops
val _ = P.printf "part 2: %d\n" result.passes
