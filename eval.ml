open Ast

exception Error of string
exception Runtime_error of span * string

let fail fmt = Printf.ksprintf (fun message -> raise (Error message)) fmt

type value =
  | Unit
  | Bool of bool
  | Int of int
  | Float of float
  | String of string
  | List of value list
  | Array of value array
  | Tuple of value list
  | Record of (string * value) list
  | Table of (string, value) Hashtbl.t
  | Variant of string * value option
  | Closure of pattern * expr * env
  | Native of (value -> value)
and env = (string * value ref) list

let rec show = function
  | Unit -> "()"
  | Bool b -> string_of_bool b
  | Int x -> string_of_int x
  | Float x -> string_of_float x
  | String s -> s
  | List xs -> "[" ^ String.concat ", " (List.map show xs) ^ "]"
  | Array xs -> "[|" ^ String.concat ", " (Array.to_list (Array.map show xs)) ^ "|]"
  | Tuple xs -> "(" ^ String.concat ", " (List.map show xs) ^ ")"
  | Record fields ->
      "{" ^ String.concat ", " (List.map (fun (k, v) -> k ^ " = " ^ show v) fields) ^ "}"
  | Table tbl -> Printf.sprintf "<table:%d>" (Hashtbl.length tbl)
  | Variant (tag, None) -> tag
  | Variant (tag, Some v) -> tag ^ " " ^ show v
  | Closure _ | Native _ -> "<function>"

let as_int = function Int i -> i | _ -> fail "expected integer"
let as_string = function String s -> s | _ -> fail "expected string"
let as_bool = function Bool b -> b | _ -> fail "expected boolean"
let as_list = function List xs -> xs | _ -> fail "expected list"
let as_array = function Array xs -> xs | _ -> fail "expected array"
let as_record = function Record xs -> xs | _ -> fail "expected record"
let bind env name value = (name, ref value) :: env

let lookup env name =
  match List.assoc_opt name env with
  | Some cell -> !cell
  | None -> fail "unbound name: %s" name

let rec equal a b = match a, b with
  | Unit, Unit -> true
  | Bool x, Bool y -> x = y
  | Int x, Int y -> x = y
  | Float x, Float y -> x = y
  | String x, String y -> x = y
  | List xs, List ys | Tuple xs, Tuple ys ->
      List.length xs = List.length ys && List.for_all2 equal xs ys
  | Array xs, Array ys ->
      Array.length xs = Array.length ys && Array.for_all2 equal xs ys
  | Record xs, Record ys ->
      List.length xs = List.length ys &&
      List.for_all (fun (k, v) -> match List.assoc_opt k ys with
        | Some w -> equal v w | None -> false) xs
  | Table x, Table y -> x == y
  | Variant (tx, vx), Variant (ty, vy) ->
      tx = ty && (match vx, vy with None, None -> true
        | Some x, Some y -> equal x y | _ -> false)
  | (Closure _ | Native _), _ | _, (Closure _ | Native _) ->
      fail "functions cannot be compared for equality"
  | _ -> false

let rec match_pattern pat value =
  match pat, value with
  | PWild, _ -> Some []
  | PVar name, v -> Some [name, v]
  | PInt a, Int b when a = b -> Some []
  | PBool a, Bool b when a = b -> Some []
  | PString a, String b when a = b -> Some []
  | PUnit, Unit -> Some []
  | PList ps, List xs | PTuple ps, Tuple xs -> match_list ps xs
  | PCons (head, tail), List (x :: xs) ->
      (match match_pattern head x, match_pattern tail (List xs) with
       | Some a, Some b -> Some (a @ b) | _ -> None)
  | PCtor (a, None), Variant (b, None) when a = b -> Some []
  | PCtor (a, Some p), Variant (b, Some v) when a = b -> match_pattern p v
  | _ -> None
and match_list ps xs =
  match ps, xs with
  | [], [] -> Some []
  | p :: ps, x :: xs ->
      (match match_pattern p x, match_list ps xs with
       | Some a, Some b -> Some (a @ b) | _ -> None)
  | _ -> None

let extend env pairs = List.fold_left (fun acc (k, v) -> bind acc k v) env pairs

let rec apply fn arg =
  match fn with
  | Native f -> f arg
  | Closure (pat, body, captured) ->
      (match match_pattern pat arg with
       | Some pairs -> eval (extend captured pairs) body
       | None -> fail "function argument does not match its pattern")
  | _ -> fail "attempt to call a non-function (%s)" (show fn)

and eval env expr =
  try
    match expr.node with
    | EInt x -> Int x
    | EFloat x -> Float x
    | EBool b -> Bool b
    | EString s -> String s
    | EUnit -> Unit
    | EVar name -> lookup env name
    | EList xs -> List (List.map (eval env) xs)
    | EArray xs -> Array (Array.of_list (List.map (eval env) xs))
    | ETuple xs -> Tuple (List.map (eval env) xs)
    | ERecord xs -> Record (List.map (fun (k, v) -> k, eval env v) xs)
    | EField (x, field) ->
        (match List.assoc_opt field (as_record (eval env x)) with
         | Some v -> v | None -> fail "unknown field: %s" field)
    | EApp (f, x) -> apply (eval env f) (eval env x)
    | ENeg x ->
        (match eval env x with Int i -> Int (-i) | Float f -> Float (-. f)
         | _ -> fail "unary - expects a number")
    | EBin ("andalso", a, b) ->
        Bool (as_bool (eval env a) && as_bool (eval env b))
    | EBin ("orelse", a, b) ->
        Bool (as_bool (eval env a) || as_bool (eval env b))
    | EBin (op, a, b) -> binary op (eval env a) (eval env b)
    | EIf (condition, yes, no) ->
        if as_bool (eval env condition) then eval env yes else eval env no
    | EFn (pat, body) -> Closure (pat, body, env)
    | ECase (value, branches) ->
        let v = eval env value in
        let rec choose = function
          | [] -> fail "non-exhaustive case expression"
          | (pat, body) :: rest ->
              (match match_pattern pat v with
               | None -> choose rest
               | Some pairs -> eval (extend env pairs) body)
        in choose branches
    | EDo (decls, result) ->
        let env' = List.fold_left declare env decls in
        eval env' result
  with Error msg -> raise (Runtime_error (expr.at, msg))

and binary op a b =
  match op, a, b with
  | "+", Int x, Int y -> Int (x + y)
  | "-", Int x, Int y -> Int (x - y)
  | "*", Int x, Int y -> Int (x * y)
  | ("+" | "-" | "*" | "/"), Float x, Float y ->
      Float (match op with "+" -> x +. y | "-" -> x -. y
          | "*" -> x *. y | _ -> x /. y)
  | "div", Int _, Int 0 | "mod", Int _, Int 0 -> fail "division by zero"
  | "div", Int x, Int y -> Int (x / y)
  | "mod", Int x, Int y -> Int (x mod y)
  | "^", String x, String y -> String (x ^ y)
  | "@", List xs, List ys -> List (xs @ ys)
  | "::", x, List xs -> List (x :: xs)
  | "=", x, y -> Bool (equal x y)
  | "/=", x, y -> Bool (not (equal x y))
  | ("<" | ">" | "<=" | ">="), Int x, Int y ->
      Bool (compare_order op (compare x y))
  | ("<" | ">" | "<=" | ">="), Float x, Float y ->
      Bool (compare_order op (compare x y))
  | ("<" | ">" | "<=" | ">="), String x, String y ->
      Bool (compare_order op (String.compare x y))
  | _ -> fail "invalid operands for %s: %s and %s" op (show a) (show b)

and compare_order op n = match op with
  | "<" -> n < 0 | ">" -> n > 0 | "<=" -> n <= 0 | ">=" -> n >= 0
  | _ -> false

and declare env decl =
  try
    match decl.node with
    | DVal (pat, value) ->
        (match match_pattern pat (eval env value) with
         | Some pairs -> extend env pairs
         | None -> fail "val pattern does not match")
    | DFun (name, args, body) ->
        let cell = ref Unit in
        let recursive_env = (name, cell) :: env in
        let rec curry = function
          | [] -> eval recursive_env body
          | [pat] -> Closure (pat, body, recursive_env)
          | pat :: rest ->
              let nested = List.fold_right
                (fun p b -> { node = EFn (p, b); at = body.at })
                rest body in
              Closure (pat, nested, recursive_env)
        in
        cell := curry args;
        recursive_env
    | DDatatype (_, constructors) ->
        List.fold_left (fun env (name, payload) ->
          let ctor = match payload with
            | None -> Variant (name, None)
            | Some _ -> Native (fun value -> Variant (name, Some value))
          in bind env name ctor) env constructors
  with Error msg -> raise (Runtime_error (decl.at, msg))

let eval_program env program =
  ignore (List.fold_left declare env program)

let curry2 f = Native (fun x -> Native (fun y -> f x y))
let curry3 f = Native (fun x -> Native (fun y -> Native (fun z -> f x y z)))
