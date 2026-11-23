#!/usr/bin/env ox
val update = fn state =>
  do
    val position = state.position + 1;
    val stops = state.stops + 2;
    { position
    , stops
    }
  end
val result = update { position = 4, stops = 5 }
val _ = P.printf "%d %d\n" result.position result.stops
