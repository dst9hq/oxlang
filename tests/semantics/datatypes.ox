#!/usr/bin/env ox
datatype outcome = Ok of int | Error of string
val describe = fn result =>
  case result of
      Ok n => P.sprintf "ok %d" n
    | Error message => message
val _ = print (describe (Ok 9))
val _ = print (describe (Error "failed"))
