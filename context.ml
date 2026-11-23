open Ast

let escape s =
  let b = Buffer.create (String.length s + 8) in
  String.iter (function
    | '"' -> Buffer.add_string b "\\\""
    | '\\' -> Buffer.add_string b "\\\\"
    | '\n' -> Buffer.add_string b "\\n"
    | '\r' -> Buffer.add_string b "\\r"
    | '\t' -> Buffer.add_string b "\\t"
    | c when Char.code c < 32 -> Buffer.add_string b (Printf.sprintf "\\u%04x" (Char.code c))
    | c -> Buffer.add_char b c) s;
  Buffer.contents b

let q s = "\"" ^ escape s ^ "\""
let quote_list xs = "[" ^ String.concat "," (List.map q xs) ^ "]"

let rec names_pattern = function
  | PVar s -> [s]
  | PCons (a, b) -> names_pattern a @ names_pattern b
  | PList ps | PTuple ps -> List.concat_map names_pattern ps
  | PCtor (_, Some p) -> names_pattern p
  | PWild | PInt _ | PBool _ | PString _ | PUnit | PCtor (_, None) -> []

let rec dependencies_expr expr =
  let rec go expr =
    let self = match expr.node with
      | EField ({ node = EVar module_; _ }, field) -> [module_ ^ "." ^ field]
      | _ -> [] in
    self @ (match expr.node with
    | EApp (f, x) | EPipe (f, x) | EBin (_, f, x) -> go f @ go x
    | EField (x, _) | ENeg x -> go x
    | EList xs | EArray xs | ETuple xs -> List.concat_map go xs
    | ERecord xs -> List.concat_map (fun (_, x) -> go x) xs
    | EIf (a, b, c) -> go a @ go b @ go c
    | EFn (_, body) -> go body
    | ECase (x, branches) -> go x @ List.concat_map (fun (_, body) -> go body) branches
    | EDo (decls, body) -> List.concat_map dependencies_decl decls @ go body
    | EInt _ | EFloat _ | EBool _ | EString _ | EUnit | EVar _ -> [])
  in go expr
and dependencies_decl decl = match decl.node with
  | DVal (_, x) | DValRec (_, x) -> dependencies_expr x
  | DDatatype _ -> []

let describe_decl decl =
  let kind, names = match decl.node with
    | DVal (PVar name, { node = EFn _; _ }) -> "function", [name]
    | DVal (p, _) -> "value", names_pattern p
    | DValRec (name, _) -> "function", [name]
    | DDatatype (name, _) -> "datatype", [name] in
  let line = decl.at.first.Lexing.pos_lnum in
  let last = decl.at.last.Lexing.pos_lnum in
  List.map (fun name ->
    Printf.sprintf "{\"name\":%s,\"kind\":%s,\"line\":%d,\"end_line\":%d}"
      (q name) (q kind) line last) names

let unique_sorted xs = List.sort_uniq String.compare xs

let to_json ~source program =
  let definitions = List.concat_map describe_decl program in
  let dependencies = unique_sorted (List.concat_map dependencies_decl program) in
  let digest = Digest.file source |> Digest.to_hex in
  Printf.sprintf
    "{\"schema\":1,\"source\":%s,\"digest\":%s,\"symbols\":[%s],\"references\":%s}\n"
    (q source) (q digest) (String.concat "," definitions) (quote_list dependencies)

let output_path source =
  let dirname = "_build/ox" in
  let short = Digest.to_hex (Digest.string source) |> fun s -> String.sub s 0 8 in
  let base = Filename.basename source in
  Filename.concat dirname (base ^ "." ^ short ^ ".json")

let write_if_changed path data =
  let previous =
    try
      let ic = open_in_bin path in
      Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () ->
        Some (really_input_string ic (in_channel_length ic)))
    with Sys_error _ -> None in
  if previous <> Some data then (
    let temp = path ^ ".tmp" in
    let oc = open_out_bin temp in
    Fun.protect ~finally:(fun () -> close_out_noerr oc) (fun () -> output_string oc data);
    Sys.rename temp path)

let cache ~source program =
  let json = to_json ~source program in
  if not (Sys.file_exists "_build") then Unix.mkdir "_build" 0o755;
  if not (Sys.file_exists "_build/ox") then Unix.mkdir "_build/ox" 0o755;
  let path = output_path source in
  write_if_changed path json;
  path, json
