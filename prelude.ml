open Eval

let unary f = Native f
let field name value = name, value
let module_ fields = Record fields
let module_names bindings long_name short_name value =
  bind (bind bindings long_name value) short_name value

let nonnegative index size =
  if index < 0 || index >= size then fail "index %d out of bounds (length %d)" index size

let list_module = module_ [
  field "map" (curry2 (fun f xs -> List (List.map (apply f) (as_list xs))));
  field "filter" (curry2 (fun f xs -> List (List.filter (fun x -> as_bool (apply f x)) (as_list xs))));
  field "app" (curry2 (fun f xs -> List.iter (fun x -> ignore (apply f x)) (as_list xs); Unit));
  field "foldl" (curry3 (fun f init xs ->
    List.fold_left (fun acc x -> apply f (Tuple [x; acc])) init (as_list xs)));
  field "length" (unary (fun xs -> Int (List.length (as_list xs))));
  field "rev" (unary (fun xs -> List (List.rev (as_list xs))));
  field "nth" (curry2 (fun xs i ->
    let xs = as_list xs and i = as_int i in
    nonnegative i (List.length xs);
    List.nth xs i));
  field "hd" (unary (fun xs -> match as_list xs with
    | x :: _ -> x | [] -> fail "head of empty list"));
  field "tl" (unary (fun xs -> match as_list xs with
    | _ :: tail -> List tail | [] -> fail "tail of empty list"));
]

let array_module = module_ [
  field "of_list" (unary (fun xs -> Array (Array.of_list (as_list xs))));
  field "to_list" (unary (fun xs -> List (Array.to_list (as_array xs))));
  field "length" (unary (fun xs -> Int (Array.length (as_array xs))));
  field "get" (curry2 (fun xs i ->
    let xs = as_array xs and i = as_int i in
    nonnegative i (Array.length xs);
    xs.(i)));
  field "set" (curry3 (fun xs i value ->
    let xs = as_array xs and i = as_int i in
    nonnegative i (Array.length xs);
    xs.(i) <- value; Unit));
  field "map" (curry2 (fun f xs -> Array (Array.map (apply f) (as_array xs))));
  field "filter" (curry2 (fun f xs ->
    Array (Array.of_list (Array.to_list (as_array xs)
      |> List.filter (fun x -> as_bool (apply f x))))));
  field "app" (curry2 (fun f xs ->
    Array.iter (fun x -> ignore (apply f x)) (as_array xs); Unit));
  field "foldl" (curry3 (fun f init xs ->
    Array.fold_left (fun acc x -> apply f (Tuple [x; acc])) init (as_array xs)));
]

let lines s =
  match List.rev (String.split_on_char '\n' s) with
  | "" :: rest -> List.rev rest
  | rev -> List.rev rev

let split sep source =
  if sep = "" then fail "separator must not be empty";
  let slen = String.length source and n = String.length sep in
  let rec starts i j = j = n || (i + j < slen && source.[i + j] = sep.[j] && starts i (j + 1)) in
  let rec scan start i acc =
    if i + n > slen then List.rev (String.sub source start (slen - start) :: acc)
    else if starts i 0 then scan (i + n) (i + n) (String.sub source start (i - start) :: acc)
    else scan start (i + 1) acc
  in scan 0 0 []

let string_module = module_ [
  field "lines" (unary (fun v -> List (List.map (fun s -> String s) (lines (as_string v)))));
  field "split" (curry2 (fun sep value ->
    List (List.map (fun s -> String s) (split (as_string sep) (as_string value)))));
  field "trim" (unary (fun s -> String (String.trim (as_string s))));
  field "join" (curry2 (fun sep values ->
    String (String.concat (as_string sep) (List.map as_string (as_list values)))));
  field "length" (unary (fun s -> Int (String.length (as_string s))));
  field "sub" (curry3 (fun s off len ->
    let s = as_string s and off = as_int off and len = as_int len in
    if off < 0 || len < 0 || off > String.length s - len then fail "invalid substring bounds";
    String (String.sub s off len)));
]

let int_module = module_ [
  field "parse" (unary (fun v ->
    let s = String.trim (as_string v) in
    match int_of_string_opt s with
    | Some n -> Int n | None -> fail "invalid integer: %S" s));
  field "to_string" (unary (fun v -> String (string_of_int (as_int v))));
  field "abs" (unary (fun v -> Int (abs (as_int v))));
]

let format_parts format =
  let n = String.length format in
  let text = Buffer.create n in
  let flush acc =
    if Buffer.length text = 0 then acc
    else (let s = Buffer.contents text in Buffer.clear text; (`Text s) :: acc) in
  let rec loop i acc =
    if i = n then List.rev (flush acc)
    else if format.[i] = '%' then
      if i + 1 >= n then fail "incomplete printf format"
      else if format.[i + 1] = '%' then
        (Buffer.add_char text '%'; loop (i + 2) acc)
      else if List.mem format.[i + 1] ['d'; 's'; 'f'] then
        let acc = flush acc in
        loop (i + 2) (`Hole format.[i + 1] :: acc)
      else fail "unsupported printf specifier: %%%c" format.[i + 1]
    else (Buffer.add_char text format.[i]; loop (i + 1) acc)
  in loop 0 []

let formatted is_print fmt =
  let parts = format_parts (as_string fmt) in
  let rec consume parts values =
    match parts with
    | [] ->
        let s = String.concat "" (List.rev values) in
        if is_print then (print_string s; flush stdout; Unit) else String s
    | `Text s :: rest -> consume rest (s :: values)
    | `Hole kind :: rest ->
        Native (fun value ->
          let s = match kind, value with
            | 'd', Int i -> string_of_int i
            | 's', String s -> s
            | 'f', Float f -> string_of_float f
            | _ -> fail "printf argument mismatch for %%%c" kind
          in consume rest (s :: values))
  in consume parts []

let printf_module = module_ [
  field "printf" (unary (formatted true));
  field "sprintf" (unary (formatted false));
]

let slurp path =
  let channel = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in_noerr channel) (fun () ->
    really_input_string channel (in_channel_length channel))

let spit path contents =
  let channel = open_out_bin path in
  Fun.protect ~finally:(fun () -> close_out_noerr channel) (fun () ->
    output_string channel contents)

let unix_module = module_ [
  field "read" (unary (fun v -> String (slurp (as_string v))));
  field "write" (curry2 (fun path data ->
    spit (as_string path) (as_string data); Unit));
  field "stat" (unary (fun v ->
    let st = Unix.stat (as_string v) in
    Record ["size", Int st.Unix.st_size;
      "mode", Int st.Unix.st_perm;
      "mtime", Float st.Unix.st_mtime;
      "directory", Bool (st.Unix.st_kind = Unix.S_DIR)]));
  field "getenv" (unary (fun v ->
    match Sys.getenv_opt (as_string v) with
    | Some s -> String s | None -> String ""));
  field "cwd" (unary (fun _ -> String (Sys.getcwd ())));
]

let table_module = module_ [
  field "make" (unary (fun _ -> Table (Hashtbl.create 16)));
  field "set" (curry3 (fun table key v ->
    match table with Table t -> Hashtbl.replace t (as_string key) v; Unit
      | _ -> fail "expected mutable table"));
  field "get" (curry2 (fun table key -> match table with
    | Table t -> (match Hashtbl.find_opt t (as_string key) with
        | None -> Variant ("None", None)
        | Some x -> Variant ("Some", Some x))
    | _ -> fail "expected mutable table"));
  field "length" (unary (fun table -> match table with
    | Table t -> Int (Hashtbl.length t) | _ -> fail "expected mutable table"));
]

let status_code = function
  | Unix.WEXITED n -> n
  | Unix.WSIGNALED n -> 128 + n
  | Unix.WSTOPPED n -> 128 + n

let run_process value =
  let args = List.map as_string (as_list value) in
  match args with
  | [] -> fail "Process.run requires a nonempty argument list"
  | command :: _ ->
      let out_file = Filename.temp_file "ox-out-" ".tmp" in
      let err_file = Filename.temp_file "ox-err-" ".tmp" in
      Fun.protect
        ~finally:(fun () ->
          (try Sys.remove out_file with _ -> ());
          (try Sys.remove err_file with _ -> ()))
        (fun () ->
          let outfd = Unix.openfile out_file [Unix.O_WRONLY; Unix.O_TRUNC] 0o600 in
          let errfd = Unix.openfile err_file [Unix.O_WRONLY; Unix.O_TRUNC] 0o600 in
          let pid =
            Fun.protect
              ~finally:(fun () -> Unix.close outfd; Unix.close errfd)
              (fun () -> Unix.create_process command (Array.of_list args) Unix.stdin outfd errfd)
          in
          let _, code = Unix.waitpid [] pid in
          Record ["status", Int (status_code code);
            "stdout", String (slurp out_file);
            "stderr", String (slurp err_file)])

let process_module = module_ [
  field "run" (unary run_process);
]

let escape_regexp_char = function
  | '.' | '+' | '(' | ')' | '{' | '}' | '[' | ']' | '^' | '$' | '|' | '\\' as c -> "\\" ^ String.make 1 c
  | c -> String.make 1 c

let glob pattern =
  let dir = Filename.dirname pattern and name = Filename.basename pattern in
  let pattern = String.to_seq name |> List.of_seq
    |> List.map (function '*' -> ".*" | '?' -> "." | c -> escape_regexp_char c)
    |> String.concat "" in
  let re = Str.regexp ("^" ^ pattern ^ "$") in
  Sys.readdir dir |> Array.to_list
  |> List.filter (fun n -> Str.string_match re n 0)
  |> List.sort String.compare
  |> List.map (fun n -> if dir = "." then n else Filename.concat dir n)

let path_module = module_ [
  field "glob" (unary (fun value -> List (List.map (fun s -> String s) (glob (as_string value)))));
  field "basename" (unary (fun s -> String (Filename.basename (as_string s))));
  field "dirname" (unary (fun s -> String (Filename.dirname (as_string s))));
]

let initial_env argv =
  let e = [] in
  let e = bind e "argv" (List (List.map (fun s -> String s) argv)) in
  let e = bind e "print" (unary (fun v -> print_endline (show v); Unit)) in
  let e = bind e "eprint" (unary (fun v -> prerr_endline (show v); Unit)) in
  let e = bind e "exit" (unary (fun v -> Stdlib.exit (as_int v))) in
  let e = bind e "glob" (unary (fun v -> List (List.map (fun s -> String s) (glob (as_string v))))) in
  let e = bind e "Some" (unary (fun v -> Variant ("Some", Some v))) in
  let e = bind e "None" (Variant ("None", None)) in
  let e = module_names e "List" "L" list_module in
  let e = module_names e "Array" "A" array_module in
  let e = module_names e "String" "S" string_module in
  let e = module_names e "Printf" "P" printf_module in
  let e = module_names e "Unix" "U" unix_module in
  let e = module_names e "Int" "I" int_module in
  let e = module_names e "Table" "T" table_module in
  let e = bind e "Process" process_module in
  let e = bind e "Path" path_module in
  e
