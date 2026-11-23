#!/usr/bin/env ox
val values = [|10, 20, 30|]
val _ = A.set values 1 99
val table = T.make ()
val _ = T.set table "answer" (A.get values 1)
val _ = case T.get table "answer" of
    Some n => P.printf "%d %d\n" (A.get values 0) n
  | None => P.printf "missing\n"
