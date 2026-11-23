{
open Parser
exception Error of Lexing.position * string
let error lexbuf message = raise (Error (lexbuf.Lexing.lex_curr_p, message))
let newline lexbuf = Lexing.new_line lexbuf
let string_buf = Buffer.create 64
}

let digit = ['0'-'9']
let alpha = ['a'-'z' '_']
let upper = ['A'-'Z']
let ident_char = ['a'-'z' 'A'-'Z' '0'-'9' '_']

rule token = parse
  | [' ' '\t' '\r'] { token lexbuf }
  | '\n' { newline lexbuf; token lexbuf }
  | "#!" [^ '\n']* { token lexbuf }
  | '#' [^ '\n']* { token lexbuf }
  | "(*" { comment 1 lexbuf; token lexbuf }
  | digit+ '.' digit+ as s { FLOAT (float_of_string s) }
  | digit+ as s { INT (int_of_string s) }
  | '"' { Buffer.clear string_buf; quoted lexbuf }
  | "val" { VAL }
  | "rec" { REC }
  | "fn" { FN }
  | "datatype" { DATATYPE }
  | "case" { CASE }
  | "of" { OF }
  | "if" { IF }
  | "then" { THEN }
  | "else" { ELSE }
  | "do" { DO }
  | "end" { END }
  | "true" { TRUE }
  | "false" { FALSE }
  | "andalso" { ANDALSO }
  | "orelse" { ORELSE }
  | "div" { DIV }
  | "mod" { MOD }
  | "o" { O }
  | '_' { UNDERSCORE }
  | alpha ident_char* as s { IDENT s }
  | upper ident_char* as s { UIDENT s }
  | "[|" { LARRAY }
  | "|]" { RARRAY }
  | "=>" { DARROW }
  | "::" { CONS }
  | "|>" { PIPE }
  | "/=" { NE }
  | "==" { EQEQ }
  | "<=" { LE }
  | ">=" { GE }
  | '(' { LPAREN }
  | ')' { RPAREN }
  | '[' { LBRACK }
  | ']' { RBRACK }
  | '{' { LBRACE }
  | '}' { RBRACE }
  | ',' { COMMA }
  | ';' { SEMI }
  | '.' { DOT }
  | '=' { EQ }
  | '<' { LT }
  | '>' { GT }
  | '+' { PLUS }
  | '-' { MINUS }
  | '*' { STAR }
  | '/' { SLASH }
  | '@' { AT }
  | '^' { CARET }
  | '|' { BAR }
  | eof { EOF }
  | _ as c { error lexbuf (Printf.sprintf "unexpected character %C" c) }

and quoted = parse
  | '"' { STRING (Buffer.contents string_buf) }
  | "\\n" { Buffer.add_char string_buf '\n'; quoted lexbuf }
  | "\\t" { Buffer.add_char string_buf '\t'; quoted lexbuf }
  | "\\r" { Buffer.add_char string_buf '\r'; quoted lexbuf }
  | "\\\"" { Buffer.add_char string_buf '"'; quoted lexbuf }
  | "\\\\" { Buffer.add_char string_buf '\\'; quoted lexbuf }
  | '\n' { newline lexbuf; error lexbuf "newline in string literal" }
  | eof { error lexbuf "unterminated string literal" }
  | _ as c { Buffer.add_char string_buf c; quoted lexbuf }

and comment depth = parse
  | "(*" { comment (depth + 1) lexbuf }
  | "*)" { if depth > 1 then comment (depth - 1) lexbuf }
  | '\n' { newline lexbuf; comment depth lexbuf }
  | eof { error lexbuf "unterminated comment" }
  | _ { comment depth lexbuf }
