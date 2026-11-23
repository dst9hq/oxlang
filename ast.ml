type span = { first : Lexing.position; last : Lexing.position }
type 'a located = { node : 'a; at : span }

let span first last = { first; last }
let located first last node = { node; at = span first last }

type pattern =
  | PWild
  | PVar of string
  | PInt of int
  | PBool of bool
  | PString of string
  | PUnit
  | PList of pattern list
  | PTuple of pattern list
  | PCons of pattern * pattern
  | PCtor of string * pattern option

type expr = expr_desc located
and expr_desc =
  | EInt of int
  | EFloat of float
  | EBool of bool
  | EString of string
  | EUnit
  | EVar of string
  | EList of expr list
  | EArray of expr list
  | ETuple of expr list
  | ERecord of (string * expr) list
  | EField of expr * string
  | EApp of expr * expr
  | ENeg of expr
  | EBin of string * expr * expr
  | EIf of expr * expr * expr
  | EFn of pattern * expr
  | ECase of expr * (pattern * expr) list
  | EDo of decl list * expr
and decl = decl_desc located
and decl_desc =
  | DVal of pattern * expr
  | DFun of string * pattern list * expr
  | DDatatype of string * (string * string option) list

type program = decl list

let location_string at =
  let p = at.first in
  Printf.sprintf "%s:%d:%d" p.Lexing.pos_fname p.pos_lnum
    (p.pos_cnum - p.pos_bol + 1)
