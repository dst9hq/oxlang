#!/usr/bin/env ox
val result =
  do
    val x = 4;
    val y = x + 6;
    { x, y }
  end
val _ = result.y
