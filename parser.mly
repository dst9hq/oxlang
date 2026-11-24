%{
open Ast
let e a b node = located a b node
let d a b node = located a b node

(* Parameter heads are parsed as parenthesized expressions, then checked
   as patterns. This avoids an LR conflict between (pattern) and (expr). *)
let rec parameter_pattern x = match x.node with
  | EParen inner -> pattern_body inner
  | _ -> failwith "syntax error: arrow parameters must be parenthesized"
and pattern_body x = match x.node with
  | EParen inner -> pattern_body inner
  | EVar "_" -> PWild
  | EVar name when String.length name > 0 && name.[0] >= 'A' && name.[0] <= 'Z' ->
      PCtor (name, None)
  | EVar name -> PVar name
  | EInt n -> PInt n
  | ENeg { node = EInt n; _ } -> PInt (-n)
  | EBool b -> PBool b
  | EString s -> PString s
  | EUnit -> PUnit
  | ETuple xs -> PTuple (List.map pattern_body xs)
  | EList xs -> PList (List.map pattern_body xs)
  | EBin ("::", a, b) -> PCons (pattern_body a, pattern_body b)
  | EApp ({ node = EVar name; _ }, arg) when
      String.length name > 0 && name.[0] >= 'A' && name.[0] <= 'Z' ->
      PCtor (name, Some (pattern_body arg))
  | _ -> failwith "syntax error: invalid arrow parameter pattern"

let make_lambda start finish head (rest, body) =
  let params = List.map parameter_pattern (head :: rest) in
  List.fold_right (fun pat body -> e start finish (EFn (pat, body))) params body
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING IDENT UIDENT
%token VAL REC DATATYPE OF CASE IF THEN ELSE DO END
%token TRUE FALSE ANDALSO ORELSE DIV MOD O
%token LPAREN RPAREN LBRACK RBRACK LARRAY RARRAY
%token LBRACE RBRACE COMMA SEMI DOT
%token EQ EQEQ NE LT GT LE GE PLUS MINUS STAR SLASH AT CARET CONS
%token BAR ARROW DARROW UNDERSCORE PIPE EOF

%start <Ast.program> program
%%

program:
  | ds=list(decl) EOF { ds }

decl:
  | VAL p=pattern EQ rhs=decl_rhs
      { match rhs with
        | `Plain x -> d $startpos $endpos (DVal (p, x))
        | `Recursive x ->
            (match p with
             | PVar name -> d $startpos $endpos (DValRec (name, x))
             | _ -> failwith "syntax error: rec requires a named val binding") }
  | DATATYPE name=IDENT EQ cs=separated_nonempty_list(BAR, constructor)
      { d $startpos $endpos (DDatatype (name, cs)) }

(* 'rec' is only legal on the right of a named 'val', never as an
   independently usable expression. An arrow tail is mandatory. *)
decl_rhs:
  | x=expr { `Plain x }
  | REC head=pipe_expr tail=arrow_tail
      { `Recursive (make_lambda $startpos $endpos head tail) }

arrow_tail:
  | DARROW body=expr { ([], body) }
  | ARROW head=pipe_expr tail=arrow_tail
      { let rest, body = tail in (head :: rest, body) }

constructor:
  | name=UIDENT { (name, None) }
  | name=UIDENT OF ty=type_spec { (name, Some ty) }

type_spec:
  | xs=separated_nonempty_list(STAR, type_atom) { String.concat " * " xs }

type_atom:
  | xs=nonempty_list(IDENT) { String.concat " " xs }
  | LPAREN t=type_spec RPAREN { "(" ^ t ^ ")" }

pattern:
  | p=simple_pattern CONS tail=pattern { PCons (p, tail) }
  | p=simple_pattern { p }

simple_pattern:
  | name=UIDENT p=atomic_pattern { PCtor (name, Some p) }
  | p=atomic_pattern { p }

atomic_pattern:
  | UNDERSCORE { PWild }
  | name=IDENT { PVar name }
  | n=INT { PInt n }
  | TRUE { PBool true }
  | FALSE { PBool false }
  | s=STRING { PString s }
  | name=UIDENT { PCtor (name, None) }
  | LPAREN RPAREN { PUnit }
  | LPAREN p=pattern RPAREN { p }
  | LPAREN p=pattern COMMA ps=separated_nonempty_list(COMMA, pattern) RPAREN
      { PTuple (p :: ps) }
  | LBRACK ps=separated_list(COMMA, pattern) RBRACK { PList ps }

expr:
  | IF cond=expr THEN yes=expr ELSE no=expr
      { e $startpos $endpos (EIf (cond, yes, no)) }
  | CASE x=expr OF bs=branches
      { e $startpos $endpos (ECase (x, bs)) }
  | DO ds=list(block_decl) x=expr END
      { e $startpos $endpos (EDo (ds, x)) }
  | head=pipe_expr tail=option(arrow_tail)
      { match tail with
        | None -> head
        | Some tail -> make_lambda $startpos $endpos head tail }

block_decl:
  | d=decl SEMI { d }

branches:
  | option(BAR) bs=separated_nonempty_list(BAR, branch) { bs }

branch:
  | p=pattern DARROW x=expr { (p, x) }

(* The pipe is left-associative and binds less tightly than all other
   infix operators. Retain its own AST node to evaluate data before function. *)
pipe_expr:
  | a=pipe_expr PIPE f=or_expr { e $startpos $endpos (EPipe (a, f)) }
  | x=or_expr { x }

or_expr:
  | a=or_expr ORELSE b=and_expr { e $startpos $endpos (EBin ("orelse", a, b)) }
  | x=and_expr { x }

and_expr:
  | a=and_expr ANDALSO b=compose_expr { e $startpos $endpos (EBin ("andalso", a, b)) }
  | x=compose_expr { x }

(* Standard ML-style, right-associative function composition: f o g. *)
compose_expr:
  | f=cmp_expr O g=compose_expr { e $startpos $endpos (EBin ("o", f, g)) }
  | x=cmp_expr { x }

cmp_expr:
  | a=append_expr EQEQ b=append_expr { e $startpos $endpos (EBin ("==", a, b)) }
  | a=append_expr NE b=append_expr { e $startpos $endpos (EBin ("/=", a, b)) }
  | a=append_expr LT b=append_expr { e $startpos $endpos (EBin ("<", a, b)) }
  | a=append_expr GT b=append_expr { e $startpos $endpos (EBin (">", a, b)) }
  | a=append_expr LE b=append_expr { e $startpos $endpos (EBin ("<=", a, b)) }
  | a=append_expr GE b=append_expr { e $startpos $endpos (EBin (">=", a, b)) }
  | x=append_expr { x }

append_expr:
  | a=cons_expr AT b=append_expr { e $startpos $endpos (EBin ("@", a, b)) }
  | x=cons_expr { x }

cons_expr:
  | a=add_expr CONS b=cons_expr { e $startpos $endpos (EBin ("::", a, b)) }
  | x=add_expr { x }

add_expr:
  | a=add_expr PLUS b=mul_expr { e $startpos $endpos (EBin ("+", a, b)) }
  | a=add_expr MINUS b=mul_expr { e $startpos $endpos (EBin ("-", a, b)) }
  | a=add_expr CARET b=mul_expr { e $startpos $endpos (EBin ("^", a, b)) }
  | x=mul_expr { x }

mul_expr:
  | a=mul_expr STAR b=unary_expr { e $startpos $endpos (EBin ("*", a, b)) }
  | a=mul_expr SLASH b=unary_expr { e $startpos $endpos (EBin ("/", a, b)) }
  | a=mul_expr DIV b=unary_expr { e $startpos $endpos (EBin ("div", a, b)) }
  | a=mul_expr MOD b=unary_expr { e $startpos $endpos (EBin ("mod", a, b)) }
  | x=unary_expr { x }

unary_expr:
  | MINUS x=unary_expr { e $startpos $endpos (ENeg x) }
  | x=application { x }

application:
  | f=application x=projection { e $startpos $endpos (EApp (f, x)) }
  | x=projection { x }

projection:
  | x=projection DOT name=IDENT { e $startpos $endpos (EField (x, name)) }
  | x=atom { x }

atom:
  | n=INT { e $startpos $endpos (EInt n) }
  | f=FLOAT { e $startpos $endpos (EFloat f) }
  | s=STRING { e $startpos $endpos (EString s) }
  | TRUE { e $startpos $endpos (EBool true) }
  | FALSE { e $startpos $endpos (EBool false) }
  | name=IDENT { e $startpos $endpos (EVar name) }
  | UNDERSCORE { e $startpos $endpos (EVar "_") }
  | name=UIDENT { e $startpos $endpos (EVar name) }
  | LPAREN RPAREN { e $startpos $endpos (EParen (e $startpos $endpos EUnit)) }
  | LPAREN x=expr RPAREN { e $startpos $endpos (EParen x) }
  | LPAREN x=expr COMMA xs=separated_nonempty_list(COMMA, expr) RPAREN
      { e $startpos $endpos (EParen (e $startpos $endpos (ETuple (x :: xs)))) }
  | LBRACK xs=separated_list(COMMA, expr) RBRACK
      { e $startpos $endpos (EList xs) }
  | LARRAY xs=separated_list(COMMA, expr) RARRAY
      { e $startpos $endpos (EArray xs) }
  | LBRACE fields=separated_list(COMMA, record_field) RBRACE
      { e $startpos $endpos (ERecord fields) }

record_field:
  | name=IDENT EQ value=expr { (name, value) }
  | name=IDENT { (name, e $startpos $endpos (EVar name)) }
