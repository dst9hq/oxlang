# Standard ML Grammar

This page describes the full grammar of the core and module language of
[Standard ML ('97
revision)](http://mitpress.mit.edu/books/definition-standard-ml),
including all "derived forms" from Appendix A of the language
definition.

See [below](#notation) for explanation of the notation.

## <span id="core">Core Language</span>

### <span id="con">Constants</span>

|  |  |  |  |
|----|----|----|----|
| *con* | ::=   | *int* | integer |
|  |  | *word* | word |
|  |  | *float* | floating point |
|  |  | *char* | character |
|  |  | *string* | string |
| *int* | ::= | ⟨`~`⟩*num* | decimal |
|  |  | ⟨`~`⟩`0x`*hex* | hexadecimal |
| *word* | ::= | `0w`*num* | decimal |
|  |  | `0wx`*hex* | hexadecimal |
| *float* | ::= | ⟨`~`⟩*num*`.`*num* | floating point |
|  |  | ⟨`~`⟩*num*⟨`.`*num*⟩`e`⟨`~`⟩*num*    | scientific |
| *char* | ::= | `#"`*ascii*`"` | character |
| *string*   | ::= | `"`⟨*ascii*⟩\*`"` | string |
| *num* | ::= | ⟨*digit*⟩<sup>+</sup> | number |
| *hex* | ::= | ⟨*digit* \| *letter*⟩<sup>+</sup> | hexadecimal number (letters may only be in the range A-F) |
| *ascii* | ::= | ... | single non-`"` ASCII character or `\`-headed escape sequence |

### <span id="id">Identifiers</span>

|  |  |  |  |
|----|----|----|----|
| *id* | ::=   | *letter*⟨*letter* \| *digit* \| `'` \| `_`⟩\* | alphanumeric |
|  |  | ⟨`!` \| `%` \| `&` \| `$` \| `#` \| `+` \| `-` \| `/` \| `:` \| `<` \| `=` \| `>` \| `?` \| `@` \| `\` \| `~` \| `` ` `` \| `^` \| `|` \| `*`⟩<sup>+</sup>    | symbolic (not allowed for type variables or module language identifiers) |
| *var* | ::= | `'`⟨*letter* \| *digit* \| `'` \| `_`⟩\* | unconstrained |
|  |  | `''`⟨*letter* \| *digit* \| `'` \| `_`⟩\* | equality |
| *longid*    | ::= | *id*<sub>1</sub>`.`···`.`*id*<sub>*n*</sub> | qualified (*n* ≥ 1) |
| *lab* | ::= | *id* | identifier |
|  |  | *num* | number (may not start with `0`) |

### <span id="exp">Expressions</span>

|  |  |  |  |
|----|----|----|----|
| *exp* | ::=   | *con* | constant |
|  |  | ⟨`op`⟩ *longid* | value or constructor identifier |
|  |  | *exp*<sub>1</sub> *exp*<sub>2</sub> | application |
|  |  | *exp*<sub>1</sub> *id* *exp*<sub>2</sub> | infix application |
|  |  | `(` *exp* `)` | parentheses |
|  |  | `(` *exp*<sub>1</sub> `,` ... `,` *exp*<sub>*n*</sub> `)` | tuple (*n* ≠ 1) |
|  |  | `{` ⟨*exprow*⟩ `}`    | record |
|  |  | `#` *lab* | record selector |
|  |  | `[` *exp*<sub>1</sub> `,` ... `,` *exp*<sub>*n*</sub> `]` | list (*n* ≥ 0) |
|  |  | `(` *exp*<sub>1</sub> `;` ... `;` *exp*<sub>*n*</sub> `)` | sequence (*n* ≥ 2) |
|  |  | `let` *dec* `in` *exp*<sub>1</sub> `;` ... `;` *exp*<sub>*n*</sub> `end`    | local declaration (*n* ≥ 1) |
|  |  | *exp* `:` *typ* | type annotation |
|  |  | `raise` *exp* | exception raising |
|  |  | *exp* `handle` *match* | exception handling |
|  |  | *exp*<sub>1</sub> `andalso` *exp*<sub>2</sub> | conjunction |
|  |  | *exp*<sub>1</sub> `orelse` *exp*<sub>2</sub> | disjunction |
|  |  | `if` *exp*<sub>1</sub> `then` *exp*<sub>2</sub> `else` *exp*<sub>3</sub> | conditional |
|  |  | `while` *exp*<sub>1</sub> `do` *exp*<sub>2</sub> | iteration |
|  |  | `case` *exp* `of` *match* | case analysis |
|  |  | `fn` *match* | function |
|  |  |  |  |
| *exprow*    | ::= | *lab* `=` *exp* ⟨`,` *exprow*⟩ | expression row |
|  |  |  |  |
| *match*    | ::= | *pat* `=>` *exp* ⟨`|` *match*⟩ | match |

### <span id="pat">Patterns</span>

|  |  |  |  |
|----|----|----|----|
| *pat*    | ::=   | *con* | constant |
|  |  | `_` | wildcard |
|  |  | ⟨`op`⟩ *id* | variable |
|  |  | ⟨`op`⟩ *longid* ⟨*pat*⟩ | construction |
|  |  | *pat*<sub>1</sub> *id* *pat*<sub>2</sub> | infix construction |
|  |  | `(` *pat* `)` | parentheses |
|  |  | `(` *pat*<sub>1</sub> `,` ... `,` *pat*<sub>*n*</sub> `)` | tuple (*n* ≠ 1) |
|  |  | `{` ⟨*patrow*⟩ `}`    | record |
|  |  | `[` *pat*<sub>1</sub> `,` ... `,` *pat*<sub>*n*</sub> `]` | list (*n* ≥ 0) |
|  |  | *pat* `:` *typ* | type annotation |
|  |  | ⟨`op`⟩ *id* ⟨`:` *typ*⟩ `as` *pat* | layered |
|  |  |  |  |
| *patrow*    | ::= | `...` | wildcard |
|  |  | *lab* `=` *pat* ⟨`,` *patrow*⟩ | pattern |
|  |  | *id* ⟨`:` *typ*⟩ ⟨`as` *pat*⟩ ⟨`,` *patrow*⟩    | variable |

### <span id="typ">Types</span>

|  |  |  |  |
|----|----|----|----|
| *typ*    | ::=   | *var* | variable |
|  |  | ⟨*typ*⟩<sup>(,)</sup> *longid* | constructor |
|  |  | `(` *typ* `)` | parentheses |
|  |  | *typ*<sub>1</sub> `->` *typ*<sub>2</sub> | function |
|  |  | *typ*<sub>1</sub> `*` ... `*` *typ*<sub>*n*</sub> | tuple (*n* ≥ 2) |
|  |  | `{` ⟨*typrow*⟩ `}`    | record |
|  |  |  |  |
| *typrow*    | ::= | *lab* `:` *typ* ⟨`,` *typrow*⟩    | type row |

### <span id="dec">Declarations</span>

|  |  |  |  |
|----|----|----|----|
| *dec* | ::=   | `val` ⟨*var*⟩<sup>(,)</sup> *valbind* | value |
|  |  | `fun` ⟨*var*⟩<sup>(,)</sup> *funbind* | function |
|  |  | `type` *typbind* | type |
|  |  | `datatype` *datbind* ⟨`withtype` *typbind*⟩ | data type |
|  |  | `datatype` *id* `=` `datatype` *longid* | data type replication |
|  |  | `abstype` *datbind* ⟨`withtype` *typbind*⟩ `with` *dec* `end` | abstract type |
|  |  | `exception` *exnbind* | exception |
|  |  | `structure` *strbind* | structure (not allowed inside expressions) |
|  |  |  | empty |
|  |  | *dec*<sub>1</sub> ⟨`;`⟩ *dec*<sub>2</sub> | sequence |
|  |  | `local` *dec*<sub>1</sub> `in` *dec*<sub>2</sub> `end` | local |
|  |  | `open` *longid*<sub>1</sub> ... *longid*<sub>*n*</sub> | inclusion (*n* ≥ 1) |
|  |  | `nonfix` *id*<sub>1</sub> ... *id*<sub>*n*</sub> | nonfix (*n* ≥ 1) |
|  |  | `infix` ⟨*digit*⟩ *id*<sub>1</sub> ... *id*<sub>*n*</sub> | left-associative infix (*n* ≥ 1) |
|  |  | `infixr` ⟨*digit*⟩ *id*<sub>1</sub> ... *id*<sub>*n*</sub> | right-associative infix (*n* ≥ 1) |
|  |  |  |  |
| *valbind* | ::= | *pat* `=` *exp* ⟨`and` *valbind*⟩ | destructuring |
|  |  | `rec` *valbind* | recursive |
|  |  |  |  |
| *funbind* | ::= | *funmatch* ⟨`and` *funbind*⟩ | clausal function |
|  |  |  |  |
| *funmatch* | ::= | ⟨`op`⟩ *id* *pat*<sub>1</sub> ... *pat*<sub>*n*</sub> ⟨`:` *typ*⟩ `=` *exp* ⟨`|` *funmatch*⟩    | nonfix (*n* ≥ 1) |
|  |  | *pat*<sub>1</sub> *id* *pat*<sub>2</sub> ⟨`:` *typ*⟩ `=` *exp* ⟨`|` *funmatch*⟩ | infix |
|  |  | `(` *pat*<sub>1</sub> *id* *pat*<sub>2</sub> `)` *pat'*<sub>1</sub> ... *pat'*<sub>*n*</sub> ⟨`:` *typ*⟩ `=` *exp* ⟨`|` *funmatch*⟩    | infix (*n* ≥ 0) |
|  |  |  |  |
| *typbind* | ::= | ⟨*var*⟩<sup>(,)</sup> *id* `=` *typ* ⟨`and` *typbind*⟩ | abbreviation |
|  |  |  |  |
| *datbind* | ::= | ⟨*var*⟩<sup>(,)</sup> *id* `=` *conbind* ⟨`and` *datbind*⟩    | data type |
|  |  |  |  |
| *conbind* | ::= | *id* ⟨`of` *typ*⟩ ⟨`|` *conbind*⟩    | data constructor |
|  |  |  |  |
| *exnbind*   | ::= | *id* ⟨`of` *typ*⟩ ⟨`and` *exnbind*⟩ | generative |
|  |  | *id* `=` *longid* ⟨`and` *exnbind*⟩ | renaming |

<sub>Note: Omitted `op` on constructors.</sub>

## <span id="module">Module Language</span>

### <span id="str">Structures</span>

|  |  |  |  |
|----|----|----|----|
| *str*    | ::=   | *longid* | identifier |
|  |  | `struct` *dec* `end` | structure |
|  |  | *str* `:` *sig* | transparent annotation |
|  |  | *str* `:>` *sig* | opaque annotation |
|  |  | *id* `(` *str* `)` | functor application |
|  |  | *id* `(` *dec* `)` | functor application |
|  |  | `let` *dec* `in` *str* `end`    | local declaration |
|  |  |  |  |
| *strbind*   | ::= | *id* ⟨`:`⟨`>`⟩ *sig*⟩ `=` *str* ⟨`and` *strbind*⟩    | structure |

### <span id="sig">Signatures</span>

|  |  |  |  |
|----|----|----|----|
| *sig* | ::=   | *id* | identifier |
|  |  | `sig` *spec* `end` | signature |
|  |  | *sig* `where` `type` *typrefin* | refinement |
|  |  |  |  |
| *typrefin* | ::= | ⟨*var*⟩<sup>(,)</sup> *longid* `=` *typ* ⟨`and` `type` *typrefin*⟩ | type refinement |
|  |  |  |  |
| *spec* | ::= | `val` *valdesc* | value |
|  |  | `type` *typdesc* | type |
|  |  | `eqtype` *typdesc* | equality type |
|  |  | `type` *typbind* | type abbreviation |
|  |  | `datatype` *datdesc* | data type |
|  |  | `datatype` *id* `=` `datatype` *longid* | data type replication |
|  |  | `exception` *exndesc* | exception |
|  |  | `structure` *strdesc* | structure |
|  |  |  | empty |
|  |  | *spec*<sub>1</sub> ⟨`;`⟩ *spec*<sub>2</sub> | sequence |
|  |  | `include` *sig* | inclusion |
|  |  | `include` *id*<sub>1</sub> ... *id*<sub>*n*</sub> | inclusion (*n* ≥ 1) |
|  |  | *spec* `sharing` `type` *longid*<sub>1</sub> `=` ... `=` *longid*<sub>*n*</sub>    | type sharing (*n* ≥ 2) |
|  |  | *spec* `sharing` *longid*<sub>1</sub> `=` ... `=` *longid*<sub>*n*</sub> | structure sharing (*n* ≥ 2) |
|  |  |  |  |
| *valdesc* | ::= | *id* `:` *typ* ⟨`and` *valdesc*⟩ | value |
|  |  |  |  |
| *typdesc* | ::= | ⟨*var*⟩<sup>(,)</sup> *id* ⟨`and` *typdesc*⟩ | abstract type |
|  |  |  |  |
| *datdesc* | ::= | ⟨*var*⟩<sup>(,)</sup> *id* `=` *condesc* ⟨`and` *datdesc*⟩    | data type |
|  |  |  |  |
| *condesc* | ::= | *id* ⟨`of` *typ*⟩ ⟨`|` *condesc*⟩    | data constructor |
|  |  |  |  |
| *exndesc*   | ::= | *id* ⟨`of` *typ*⟩ ⟨`and` *exndesc*⟩ | exception |
|  |  |  |  |
| *strdesc* | ::= | *id* `:` *sig* ⟨`and` *strdesc*⟩ | structure |

### <span id="prog">Programs</span>

|  |  |  |  |
|----|----|----|----|
| *prog* | ::=   | *dec* | core declaration |
|  |  | `functor` *fctbind* | functor declaration |
|  |  | `signature` *sigbind* | signature declaration |
|  |  |  | empty |
|  |  | *prog*<sub>1</sub> ⟨`;`⟩ *prog*<sub>2</sub> | sequence |
|  |  |  |  |
| *fctbind* | ::= | *id*<sub>1</sub> `(` *id*<sub>2</sub> `:` *sig* `)` ⟨`:`⟨`>`⟩ *sig*⟩ `=` *str* ⟨`and` *fctbind*⟩    | plain |
|  |  | *id* `(` *spec* `)` ⟨`:`⟨`>`⟩ *sig*⟩ `=` *str* ⟨`and` *fctbind*⟩ | opened |
|  |  |  |  |
| *sigbind*    | ::= | *id* `=` *sig* ⟨`and` *sigbind*⟩ | signature |

<sub>Note: Omitted *exp*`;` derived form for interactive toplevel.</sub>

## <span id="notation">Notation</span>

We liberally use the following notation in the grammar:

- ⟨*foo*⟩ for 0 or 1 occurrences of *foo*
- ⟨*foo*⟩\* for 0 to many occurrences of *foo*
- ⟨*foo*⟩<sup>+</sup> for 1 to many occurrences of *foo*
- ⟨*foo* \| *bar*⟩ for one of *foo* or *bar* (also with more
  alternatives)
- ⟨*foo*⟩<sup>(,)</sup> for 0 or 1 occurrences of *foo*, or 1 to many
  comma-separated occurrences enclosed in parentheses (i.e., either
  empty, *foo*, or `(`*foo*<sub>1</sub>`,`...`,`*foo*<sub>*n*</sub>`)`
  for *n* ≥ 1)

------------------------------------------------------------------------

<table data-cellpadding="0" width="100%">
<colgroup>
<col style="width: 100%" />
</colgroup>
<tbody>
<tr>
<td><a href="http://www.mpi-sws.org/~rossberg/">Andreas Rossberg</a>, <a
href="mailto:rossberg@mpi-sws.org">rossberg@mpi-sws.org</a>.<br />
Last modified: 2022/09/14 / <a
href="https://imprint.mpi-klsb.mpg.de/sws/people/rossberg">Imprint</a> /
<a
href="https://data-protection.mpi-klsb.mpg.de/sws/people/rossberg">Data
protection</a></td>
</tr>
</tbody>
</table>
