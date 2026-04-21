# Virgil Grammar

Extracted from `aeneas/src/vst/Parser.v3`. Written in EBNF; `,*` means comma-separated list, `?` means optional, `*` means zero or more.

---

## Top Level

```
File ::= ToplevelDecl*

ToplevelDecl ::=
    | ['private'] 'class'              ClassDecl
    | ['private'] 'component'          id Members
    | ['private'] 'thread' 'component' id Members
    | ['private'] 'type'               VariantDecl
    | ['private'] 'enum'               EnumDecl
    | ['private'] 'packing'            PackingDecl
    | 'import' [string] 'component'    id Members
    | 'layout'                         LayoutDecl
    | 'export'                         ExportDecl
    | 'var'  VarDef ';'
    | 'def'  DefDef ';'
```

---

## Declarations

```
ClassDecl   ::= id TypeParams? ClassParams? ('extends' TypeRef TupleExpr?)? RepHints? Members

VariantDecl ::= DottedId TypeParams? VariantCaseParams? RepHints? (';' | '{' VariantCase* '}')
VariantCase ::= 'case' id VariantCaseParams? RepHints? (';' | Members)   // named case
              | 'case' '_' RepHints? (';' | DefaultCaseMembers)           // default case: optional, must be last, at most one
              | 'def' DefDef

DefaultCaseMembers ::= '{' (['private'] 'def' DefDef)* '}'               // only methods allowed (no 'var' or 'new')

DottedId    ::= (id TypeArgs? '.')* id TypeParams?
              // qualifier parts may carry type args; final part carries type params
```

### Variant subtype constraints (checked by verifier)

A `VariantDecl` whose `DottedId` is a plain `id` is a **root** (top-level) variant.

A `VariantDecl` whose `DottedId` has the form `D.T` (one or more dots) declares a **subtype variant**:

- The first identifier in `D` must name a root variant.
- Every intermediate identifier in `D` must name a variant that is a direct subtype of the previous one (transitively established by prior declarations).
- The immediate parent (the variant named by all of `D`) must have a `case _`.
- `T` must not clash with any named `case id` of the immediate parent.
- `D.T` may be declared at most once (among all files of the program).
- RepHints (`#boxed`, `#unboxed`, etc.) are **not** allowed on subtype variants; they are only allowed on root variants.

### Subtype type parameters (pass-through)

A parameterized root variant (e.g. `type Foo<T> { ... }`) may have parameterized subtypes that **pass through** the same type parameters. The subtype must declare the same number of type parameters as the root. Two declaration forms are supported:

- **Explicit binding**: `type Foo<T>.Bar<T> { case B(v: T); }` — the qualifier carries matching type args.
- **Shorthand**: `type Foo.Bar<T> { case B(v: T); }` — the qualifier omits type args (same meaning).

When referencing a parameterized subtype, type arguments may be provided in several ways:

- `Bar<int>` — direct reference with explicit type args.
- `Foo<int>.Bar` — the left side provides type args; the subtype inherits them.
- `Foo<int>.Bar<int>` — fully explicit; right-side args must match the left.

In match patterns, unqualified subtype names (`Bar =>` or `b: Bar =>`) automatically inherit type arguments from the type being matched.

### Variant method inheritance

- A `def m` declared directly in a variant `T` is inherited by all subtype variants of `T` (transitively). It may be overridden in a subtype following the same rules as class method overrides.
- A `def m` declared in the `case _` body of variant `T` is inherited by direct subtypes of `T`. It may override a `def m` already declared on `T` or a supertype of `T`, and may itself be overridden in subtypes. A `case _` method may have no body (abstract).

```

EnumDecl    ::= DottedId EnumParams? '{' EnumCase* (';' EnumMethod*)? '}'
EnumCase    ::= id ['(' Expr,* ')'] ','?                 // named case
              | '_' ','?                                 // default case: optional, must be last, at most one

EnumMethod  ::= ['private'] 'def' DefDef                // shared by all cases

EnumParams  ::= '(' 'super' ')'                      // inherit parent's params
              | '(' 'super' ',' ParamDecl,+ ')'       // inherit parent's params + add new fields
              | '(' ParamDecl,* ')'                    // declare params (root or restate + optional extras)

```

### Enum subtype constraints (checked by verifier)

An `EnumDecl` whose `DottedId` is a plain `id` is a **root** (top-level) enum.

An `EnumDecl` whose `DottedId` has the form `D.T` (one or more dots) declares a **subtype enum**:

- The first identifier in `D` must name a root enum.
- Every intermediate identifier in `D` must name an enum that is a direct subtype of the previous one (transitively established by prior declarations).
- The immediate parent (the enum named by all of `D`) must have a `case _`.
- `T` must not clash with any named `case id` of the immediate parent.
- `D.T` may be declared at most once (among all files of the program).

### Enum subtype parameter rules

A subtype's **effective parameters** are its parent's effective parameters plus any extra parameters the subtype itself declares. The root enum's effective parameters are simply its own declared parameters.

Subtypes may reference their parent's effective parameters in several ways:

- **Form 1 (restate)**: `enum E.S(x: int)` — restates the parent's effective params by name and type. May also add extra params: `enum E.S(x: int, f: float)`.
- **Form 2 (super)**: `enum E.S(super)` — inherits the parent's effective params without restating them.
- **Form 2+add (super + extras)**: `enum E.S(super, f: float)` — inherits parent's effective params and adds new fields.
- **Form 3 (implicit)**: `enum E.S` — no param list; parent's effective params are inherited implicitly.

In all forms, each case must provide argument values for all effective parameters (parent's effective params + own extra params, in order).

In multi-level hierarchies, `super` refers to the immediate parent's effective parameters, which includes the root's parameters and all intermediate ancestors' extra parameters. For example, given `enum E(x: int)` and `enum E.S(super, y: int)`, a grandchild `enum E.S.T(super, z: int)` has effective parameters `(x, y, z)` and each case must provide all three values.

Subtypes may **not** declare params if the parent has no effective params. Using `super` when the parent has no effective params is an error.

### Enum methods

An `EnumMethod` declared after the `;` separator is shared by all cases.

### Enum method inheritance

- Methods declared on a parent enum are inherited by all subtype enums (transitively).
- A subtype enum may override an inherited method by declaring a method with the same name and signature after its own `;` separator.
- All virtual dispatch goes through the root enum's dispatch table, regardless of where the override is declared.


### Enum match pattern semantics

When matching on an expression of enum type `E`, a match pattern may name:

- A **named case** of `E` (e.g. `X` where `E` has `case X`) — matched by tag
- A **subtype enum** of `E` (e.g. `S` where `E.S` is a subtype) — matched by tag range

Only the **unqualified** name is legal in a match pattern. For example, if `E.S` is a subtype of `E`, write `S`, not `E.S`.

A match on an enum type `E` that has `case _` must always include a `_` arm regardless of which named cases or subtypes are listed.

```
PackingDecl ::= id '(' PackingParam,* ')' ':' int '=' PackingExpr ';'
PackingParam ::= id ':' int
PackingExpr  ::= BitPattern                           // 0b...
               | '#' 'solve'  '(' PackingExpr,* ')'
               | '#' 'concat' '(' PackingExpr,* ')'
               | id ['(' PackingExpr,* ')']           // application or field
               | Number

LayoutDecl  ::= '{' LayoutField* '=' int ';' '}'
LayoutField ::= '+' int id ':' MemoryTypeRef RepHints? ';'

ExportDecl  ::= [string] ('def' DefDef | id ['=' DottedVarExpr] ';')
```

---

## Members

```
Members ::= '{' Member* '}'
Member  ::= ['private'] [string]
            ( 'def' ['var'] DefDef
            | 'new'         NewDef
            | 'var'         VarDef )

NewDef  ::= MethodParams (':' 'super' TupleExpr | 'super' TupleExpr)? BlockStmt

DefDef  ::= id TypeParams? MethodParams ReturnTypeAndBody                 // method
          | id TypeParams? ':' TypeRef '=' Expr ';'                       // field alias

VarDef  ::= id [':' TypeRef] ['=' Expr] ';'

ReturnTypeAndBody ::=
    '->' ('this' | TypeRef) RepHints? ( '=>' Expr ';'   // simple body (unstable)
                                      | ';'
                                      | BlockStmt )
  | '=>' Expr                                            // implicit return type (unstable)
  | RepHints? (';' | BlockStmt)
```

---

## Types

```
TypeRef       ::= '(' TypeRef,* ')'              // tuple type
                | id ('.' id)* ('->' TypeRef)*   // named type / function type

MemoryTypeRef ::= id ('[' int ']')?

TypeParams    ::= '<' TypeParam,+ '>'
TypeParam     ::= id

ClassParams        ::= '(' ParamDecl,* ')'       // class constructor params (typed, def read-only)
MethodParams       ::= '(' ParamDecl,* ')'       // method params (optionally typed)
VariantCaseParams  ::= '(' ParamDecl,* ')'       // like enum params (typed, def read-only)
EnumParams         ::= '(' 'super' [',' ParamDecl,+] ')'   // super form (with optional extras)
                     | '(' ParamDecl,* ')'                  // typed, immutable

ParamDecl ::= ['var'] id [':' TypeRef]
```

---

## Statements

```
Stmt ::= BlockStmt
       | ';'
       | 'if'       '(' Expr ')' Stmt ('else' Stmt)?
       | 'while'    '(' Expr ')' Stmt
       | 'for'      '(' VarDecl '<'  Expr         ')' Stmt   // range:   for (i < n)
       | 'for'      '(' VarDecl 'in' Expr         ')' Stmt   // foreach: for (x in xs)
       | 'for'      '(' VarDecl ';'  Expr ';' Expr? ')' Stmt // C-style: for (;;)
       | 'match'    '(' Expr ')' '{' MatchCase* '}' ('else' Stmt)?
       | 'var'      id VarDef
       | 'def'      id (MethodParams ReturnTypeAndBody | VarDef)  // local def or nested fn
       | 'break'    ';'
       | 'continue' ';'
       | 'return'   Expr? ';'
       | Expr ';'

BlockStmt ::= '{' Stmt* '}'
```

---

## Match Cases

```
MatchCase   ::= '_' '=>' Stmt                               // wildcard
              | id ':' '_' '=>' Stmt                        // named wildcard (binds matched value to id)
              | MatchPattern (',' MatchPattern)* '=>' Stmt

MatchPattern ::= id ':' TypeRef                             // binding pattern
               | id ('.' id)* ('(' MatchParam,* ')')?      // variant / dotted name with optional destructure
               | ByteLiteral | Number
               | 'true' | 'false' | 'null'

MatchParam  ::= '_' | id
```

### Variant match pattern semantics

When matching on an expression of variant type `T`, the second rule of `MatchPattern` may name:

- A **named case** of `T` (e.g. `X` where `T` has `case X`) — matched by tag
- A **subtype variant** of `T` (e.g. `S` where `T.S` is a subtype) — matched by runtime type check (`S.?(value)`)

Only the **unqualified** name is legal in the second rule. For example, if `T.S` is a subtype of `T`, write `S`, not `T.S`.

A match on a variant type `T` that has `case _` must always include a `_` arm regardless of which named cases or subtypes are listed.

Subtype names may also appear as the `TypeRef` in the **first rule** (binding pattern `x: S`), in which case `x` is bound and cast to the subtype type.

---

## Expressions

Binary operators are parsed with a precedence-climbing stack (Pratt-style), not nested grammar rules.

```
Expr    ::= SubExpr ('=' Expr)?                 // assignment (= not ==)
          | SubExpr BinOp SubExpr ...           // binary ops with precedence

SubExpr ::= Term Suffix*

Suffix  ::= '.' MemberRef                      // field / method access
          | '(' Expr,* ')'                     // call
          | '[' ']'                            // empty index
          | '[' Expr ('...' Expr? | '..+' Expr)? ']'   // index or range slice
          | '[' Expr (',' Expr)* ']'           // multi-index
          | '++'                               // postfix increment
          | '--'                               // postfix decrement

MemberRef ::= id ['<' TypeRef,* '>']           // named member
            | '!' | '?'                        // cast / option operators
            | BinOp                            // operator member (e.g. .+)
            | decimal                          // tuple field by index (e.g. .0)
            | '~'                              // complement member
            | '[]' | '[]='                     // index operator members

Term ::= 'if'  '(' Expr (',' Expr)+ ')'        // ternary if-expression
       | 'fun' id? Params ReturnTypeAndBody     // function expression (unstable)
       | id ['<' TypeRef,* '>']                // variable reference
       | Number                                // integer, float, hex, binary
       | '\'' char '\''                        // byte literal
       | '"' ... '"'                           // string literal
       | '(' Expr,* ')'                        // tuple
       | '[' Expr,* ']'                        // array literal
       | '!' SubExpr                           // logical not
       | '~' SubExpr                           // bitwise complement
       | '-' SubExpr                           // negation
       | '--' SubExpr                          // prefix decrement
       | '++' SubExpr                          // prefix increment
       | '_'                                   // partial application hole

BinOp ::=
    // arithmetic
    '+' | '-' | '*' | '/' | '%'
    // bitwise
    | '&' | '|' | '^' | '<<' | '>>' | '>>>'
    // comparison
    | '==' | '!=' | '<' | '<=' | '>' | '>='
    // logical
    | '&&' | '||'
    // compound assignment
    | '+=' | '-=' | '*=' | '/=' | '%='
    | '&=' | '|=' | '^=' | '<<=' | '>>=' | '>>>='
```

---

## Representation Hints

Hints are attached to class, variant, enum, layout, and method declarations with `#`.

```
RepHints ::= ('#' HintName HintArgs?)*

HintName ::= id (with '-' or ':' allowed in middle, e.g. 'big-endian', 'no-inline')

HintArgs ::= '<' TypeRef,* '>'          // type hint:  #label<T>
           | '(' Expr,* ')'             // expr hint:  #label(e)
           | PackingExpr                 // packing:    #packing(...)

// Known hints: boxed, unboxed, packed, big-endian, inline, no-inline, packing(...)
```

---

## Lexical

```
id          ::= IdentStart IdentMiddle*
IdentStart  ::= [a-zA-Z]               // '_' is NOT an ident-start; it is a standalone keyword token
IdentMiddle ::= [a-zA-Z0-9_]

DottedId    ::= (id TypeArgs? '.')* id TypeParams?   // no whitespace around '.'; qualifier parts may carry type args

Number      ::= DecLiteral | HexLiteral | BinLiteral | FloatLiteral
              // suffixes: u (unsigned), i8/i16/i32/i64, u8/u16/u32/u64, f32/f64
              // '_' separators allowed in digits

Keywords    ::= break case class component continue def descriptor describes
                else enum export extends false for fun if import in layout
                match new null packing private return struct super thread
                true type var while
```
