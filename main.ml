let version = "0.1.0-dev"

let usage () =
  prerr_endline "ox - a data-oriented ML-style scripting language";
  prerr_endline "usage: ox SCRIPT.ox [args...] | ox check SCRIPT.ox | ox context SCRIPT.ox | ox --version";
  exit 2

let parse path =
  let ic = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in_noerr ic) (fun () ->
    let lexbuf = Lexing.from_channel ic in
    lexbuf.Lexing.lex_curr_p <-
      { lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = path };
    try Parser.program Lexer.token lexbuf with
    | Parser.Error ->
        let pos = Lexing.lexeme_start_p lexbuf in
        failwith (Printf.sprintf "%s:%d:%d: syntax error"
          path pos.Lexing.pos_lnum (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1))
    | Lexer.Error (pos, msg) ->
        failwith (Printf.sprintf "%s:%d:%d: %s"
          path pos.Lexing.pos_lnum (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1) msg))

let () =
  try
    match Array.to_list Sys.argv with
    | [_; "--version"] -> print_endline ("ox " ^ version)
    | [_; "check"; file] ->
        ignore (parse file);
        Printf.printf "ok: %s\n" file
    | [_; "context"; file] ->
        let program = parse file in
        let path, json = Context.cache ~source:file program in
        print_string json;
        Printf.eprintf "context cache: %s\n" path
    | _ :: file :: args when file <> "" && file.[0] <> '-' ->
        let program = parse file in
        Eval.eval_program (Prelude.initial_env args) program
    | _ -> usage ()
  with
  | Eval.Runtime_error (span, msg) ->
      Printf.eprintf "%s: %s\n" (Ast.location_string span) msg;
      exit 1
  | Eval.Error msg | Failure msg | Sys_error msg ->
      prerr_endline ("ox: " ^ msg);
      exit 1
  | Unix.Unix_error (err, fn, arg) ->
      Printf.eprintf "ox: %s(%s): %s\n" fn arg (Unix.error_message err);
      exit 1
