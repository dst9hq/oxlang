%{
open Ast
let e a b node = located a b node
let d a b node = located a b node
%}

%token <int> INT
%token <float> FLOAT
%token <string> STRING IDENT UIDENT
%token VAL REC FN DATATYPE OF CASE IF THEN ELSE DO END
%token TRUE FALSE ANDALSO ORELSE DIV MOD O
%token LPAREN RPAREN LBRACK RBRACK LARRAY RARRAY
%token LBRACE RBRACE COMMA SEMI DOT
%token EQ NE LT GT LE GE PLUS MINUS STAR SLASH AT CARET CONS
%token BAR DARROW UNDERSCORE PIPE EOF

%start <Ast.program> program
%%

program:
  | ds=list(decl) EOF { ds }

decl:
  | VAL p=pattern EQ x=expr { d $startpos $endpos (DVal (p, x)) }
  | VAL REC name=IDENT EQ body=recursive_fn
      { d $startpos $endpos (DValRec (name, body)) }
  | DATATYPE name=IDENT EQ cs=separated_nonempty_list(BAR, constructor)
      { d $startpos $endpos (DDatatype (name, cs)) }

(* Recursive bindings are restricted syntactically to lambdas.
   The parenthesized form does not admit arbitrary expressions. *)
recursive_fn:
  | FN p=pattern DARROW body=expr
      { e $startpos $endpos (EFn (p, body)) }
  | LPAREN x=recursive_fn RPAREN { x }

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
  | FN p=pattern DARROW body=expr
      { e $startpos $endpos (EFn (p, body)) }
  | CASE x=expr OF bs=branches
      { e $startpos $endpos (ECase (x, bs)) }
  | DO ds=list(block_decl) x=expr END
      { e $startpos $endpos (EDo (ds, x)) }
  | x=pipe_expr { x }

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
  | a=append_expr EQ b=append_expr { e $startpos $endpos (EBin ("=", a, b)) }
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
  | name=UIDENT { e $startpos $endpos (EVar name) }
  | LPAREN RPAREN { e $startpos $endpos EUnit }
  | LPAREN x=expr RPAREN { x }
  | LPAREN x=expr COMMA xs=separated_nonempty_list(COMMA, expr) RPAREN
      { e $startpos $endpos (ETuple (x :: xs)) }
  | LBRACK xs=separated_list(COMMA, expr) RBRACK
      { e $startpos $endpos (EList xs) }
  | LARRAY xs=separated_list(COMMA, expr) RARRAY
      { e $startpos $endpos (EArray xs) }
  | LBRACE fields=separated_list(COMMA, record_field) RBRACE
      { e $startpos $endpos (ERecord fields) }

record_field:
  | name=IDENT EQ value=expr { (name, value) }
  | name=IDENT { (name, e $startpos $endpos (EVar name)) }
