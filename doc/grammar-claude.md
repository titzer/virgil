# Virgil Grammar

Extracted from `aeneas/src/vst/Parser.v3`. Written in EBNF; `,*` means comma-separated list, `?` means optional, `*` means zero or more.

A `,*` list may carry a single trailing comma before its closing delimiter
(e.g. `[1, 2, 3,]`, `f(a, b,)`, `enum E { A, B, }`). This does not apply to
declarator lists such as `var x = 1, y = 2;`, which still require a `;`.

---

## Top Level

```
File ::= ToplevelDecl*

ToplevelDecl ::= Annotation* ToplevelDeclBody      // see Annotations, below
               | FileAnnotation
               | AnnotationTypeDecl
               | AnnotationAliasDecl

ToplevelDeclBody ::=
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
VariantCase ::= Annotation* 'case' id VariantCaseParams? RepHints? (';' | Members)   // named case
              | Annotation* 'case' '_' RepHints? (';' | DefaultCaseMembers)           // default case: optional, must be last, at most one
              | Annotation* 'def' DefDef

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

EnumDecl    ::= id EnumParams? '{' EnumCase* '}'
EnumCase    ::= Annotation* id ['(' Expr,* ')'] ','?

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
Member  ::= Annotation* ['private'] [string]
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
TypeRef       ::= Annotation*                    // annotation binds to the whole type,
                                                 //   including any '->' suffixes
                  ( '(' TypeRef,* ')'            // tuple type
                  | id ('.' id)* ) ('->' TypeRef)*   // named type / function type

MemoryTypeRef ::= id ('[' int ']')?

TypeParams    ::= '<' TypeParam,+ '>'
TypeParam     ::= Annotation* id

ClassParams        ::= '(' ParamDecl,* ')'       // class constructor params (typed, def read-only)
MethodParams       ::= '(' ParamDecl,* ')'       // method params (optionally typed)
VariantCaseParams  ::= '(' ParamDecl,* ')'       // like enum params (typed, def read-only)
EnumParams         ::= '(' ParamDecl,* ')'       // typed, immutable

ParamDecl ::= ['var'] id [':' TypeRef]
```

---

## Statements

```
Stmt ::= Annotation* BlockStmt         // Block target; annotations only before a block
       | BlockStmt
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
            | '@' id                           // annotation query (see Annotations)
            | '!' | '?'                        // cast / option operators
            | BinOp                            // operator member (e.g. .+)
            | decimal                          // tuple field by index (e.g. .0)
            | '~'                              // complement member
            | '[]' | '[]='                     // index operator members

Term ::= Annotation+ Term                       // TypeUse target in expression position
       | 'if'  '(' Expr (',' Expr)+ ')'        // ternary if-expression
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

## Annotations

**Status: proposed, not implemented.** Full rationale, ambiguity analysis, and worked
examples are in `doc/annotations-syntax.md`. Gated behind `-lang:annotations`.

```
Annotation     ::= '@' id AnnotationArgs?       // '@' glued to id: no space, no comment
AnnotationArgs ::= '(' AnnotationArg,* ')'      // '(' glued to id
AnnotationArg  ::= id '=' AnnValue              // keyword form
                 | AnnValue                     // positional form

AnnValue       ::= AnnPrimary Suffix*           // Suffix as in Expressions, above
AnnPrimary     ::= Annotation                   // @atomic, @outer, @this, ...
                 | Expr

AnnotationTypeDecl  ::= Annotation* ['private'] '@type' id AnnFields? (';' | AnnBody)
AnnFields           ::= '(' AnnField,* ')'
AnnField            ::= Annotation* id ':' TypeRef ('=' Expr)?
AnnBody             ::= '{' (['private'] 'def' DefDef)* '}'    // methods only

AnnotationAliasDecl ::= Annotation* ['private'] '@def' id '=' Annotation,+ ';'

FileAnnotation      ::= '@file' '(' Annotation,* ')' ';'       // top level only
```

Rules:

- `@` is glued to the name. `@ deprecated` and `@/*x*/deprecated` are errors.
- Annotation names are a **separate namespace** from types and values, use the ordinary
  `id` rule (no `-` or `:`, unlike hint labels), and take no type arguments.
- `@` + a **keyword** is a declaration (`@type`, `@def`); `@` + an **identifier** is a use.
- Exactly two names are reserved: `@file` and `@apply` (splice a computed annotation).
- Annotations precede all existing modifiers, including `private`.
- **The first `(` after an annotation name is arguments only when glued to it.**
  `@ann(a, b)` is two arguments; `@ann (a, b)` applies `@ann` to the tuple type `(a, b)`.
  A *second* `(` always begins the annotated type or expression, spaced or not.
- `.@name` reaches into the annotation namespace; plain `.name` does not.
  `T.@ann` is the annotation, `T.@ann.field` one of its fields, `@ann.?(T)` a presence test.
- Targets: File, AnnotationType, Class, Component, Variant, Enum, VariantCase, EnumCase,
  Field, Method, Parameter (type parameter), TypeUse, Block. Formal, Actual, Local,
  Statement, and Expression are not supported.
- A name may be **overloaded by target**: several `@type` / `@def` declarations may share a
  name provided their target sets are disjoint. Every position above determines exactly one
  target kind, so a use resolves by position. `@file` and `@apply` are not overloadable.
- An alias binds a list, and is legal where every annotation in its expansion is.

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

AnnName     ::= '@' id                 // proposed; '@' glued to id, no whitespace

DottedId    ::= (id TypeArgs? '.')* id TypeParams?   // no whitespace around '.'; qualifier parts may carry type args

Number      ::= DecLiteral | HexLiteral | BinLiteral | FloatLiteral
              // suffixes: u (unsigned), i8/i16/i32/i64, u8/u16/u32/u64, f32/f64
              // '_' separators allowed in digits

Keywords    ::= break case class component continue def descriptor describes
                else enum export extends false for fun if import in layout
                match new null packing private return struct super thread
                true type var while
```
