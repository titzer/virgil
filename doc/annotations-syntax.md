# Virgil Annotations — Syntax Proposal

Status: **proposal**. Nothing here is implemented. This document fixes the concrete syntax
so that implementation can proceed without further design decisions. The semantics —
target checking, implicit/derived annotations, type cloning — are sketched in
`doc/ideas/Annotations.txt` and are deliberately out of scope here except where they
constrain the grammar.

Notation follows `doc/grammar-claude.md`: `,*` is a comma-separated list, `?` is optional,
`*` is zero or more, `+` is one or more.

---

## 1. Design decisions

1. **`@` is glued to the annotation name.** No whitespace and no comment may appear between
   them. `@ deprecated` and `@/*x*/deprecated` are errors.
2. **Whitespace resolves the one real ambiguity.** `@ann(x)` is an argument list;
   `@ann (x)` applies `@ann` to the parenthesized type or expression `(x)`. See §7.
3. **`@` + keyword introduces a declaration; `@` + identifier is a use.** `@type` declares
   an annotation, `@def` declares an alias. The grammar reserves exactly two annotation
   names — `@file` for file-level application (§5) and `@apply` for splicing a computed
   annotation (§3.3). Every other meta-annotation — `@target`, `@required`, `@repeatable`,
   `@retention`, `@implicit`, `@clones_type` — is an ordinary `@type`, declared in the
   standard annotations file (§12).
4. **Named arguments use `=`, not `:`.** In Virgil `:` declares the *type* of something;
   an annotation argument supplies a *value*.
5. **Annotations always precede all existing modifiers**, including `private`.
6. **`.@name` crosses into the annotation namespace; plain `.name` does not.** One operator
   fetches an annotation, whether from a type or from a target designator (§3.2).

---

## 2. Lexical

```
AnnName ::= '@' Id            // '@' immediately followed by Id
```

`Id` is the ordinary `IDENTIFIER` rule. Unlike rep-hint labels, `-` and `:` are **not**
permitted mid-name, so `@big-endian` is not a legal annotation name.

Annotation names are **not parameterized**: the name scanner stops at `<`, so `@ann<T>` is
not a thing. (This is why the scanner must be hand-rolled, as `parseRepHints` is, rather
than reusing `parseIdentCommon` — which would greedily take `<...>` as type arguments.)

Annotation names occupy a **namespace of their own**. `@foo` and a class, component, or
variable named `foo` are unrelated and never collide. `private` scopes an annotation
declaration to its file exactly as it does a class.

`@` followed by a Virgil keyword introduces a declaration (§4). `@` followed by a plain
identifier is a use (§3). Two names are reserved: `@file` (§5) and `@apply` (§3.3). `@`
followed by anything else is an error.

Reserving `file` and `apply` in the annotation namespace costs nothing elsewhere: both
remain ordinary identifiers for types, components, variables, and members. The compiler's
own `ParserState.file` is unaffected.

---

## 3. Applying an annotation

### 3.1 The annotation itself

```
Annotation     ::= '@' Id AnnotationArgs?
AnnotationArgs ::= '(' AnnotationArg,* ')'          // '(' glued to Id
AnnotationArg  ::= Id '=' AnnValue                  // keyword form
                 | AnnValue                         // positional form

AnnValue       ::= AnnPrimary Suffix*               // Suffix as in the expression grammar
AnnPrimary     ::= Annotation                       // @atomic, @outer, @this, …
                 | Expr
```

`Expr` already covers every ordinary value the design needs — `TargetKind.Class`, the array
literal `[TargetKind.Class, TargetKind.Variant]`, `Date(2026, 8, 1)`, strings, arithmetic —
so no separate value grammar is required. Argument lists inherit the language-wide
allowance of a single trailing comma.

The keyword form is recognized by `Id` followed by `=` and not `==`. Inside an annotation
argument list this always wins over reading `x = 1` as an assignment expression; assignment
is not meaningful as an annotation value, since values must be compile-time constants.

Allowing `Annotation` as a primary is what lets annotations nest as values, as
`@clones_type(@atomic)` requires, and what gives the query forms of §3.2 something to hang
off. `Suffix` is the language's existing suffix chain — member selection, `.?`, and calls —
so once `MemberRef` gains the one new form below, queries need no machinery of their own.

Note that the whitespace rule of §7.1 does **not** apply inside an argument list. That rule
separates an argument list from *the construct being annotated*, and no construct is being
annotated in a value position. Within an argument list, a `(` after an annotation primary is
therefore an ordinary call suffix — meaningful after `.?`, and an error otherwise, since an
annotation is not itself callable.

### 3.2 Queries

One new member reference:

```
MemberRef ::= ... | '@' Id
```

`'.'` followed by `@` is illegal today, so this is free. It joins the seven non-identifier
forms `addMemberSuffix` already accepts after `.` — `!`, `?`, any infix operator, a decimal,
`~`, `[]`, `[]=` — of which `T.?` and `T.!` are likewise pseudo-members of a type rather
than declared members.

**`.@name` crosses into the annotation namespace; plain `.name` stays in the ordinary
member namespace.** One operator fetches an annotation, and it does not care whether its
left operand is a type or one of the target designators `@outer` / `@this`:

```
Vector<T>.@atomicity          // the @atomicity annotation of the type Vector<T>
Vector<T>.@atomicity.value    // ... and then its 'value' field
@outer.@atomicity             // the @atomicity of the immediately enclosing target
@this.@atomicity
@outer.@atomicity.value
```

Because `.@name` yields an *annotation*, not a field value, the trailing `.value` is just
the ordinary member suffix and composes for free. Keep the distinction in mind when
supplying a list to `@implicit`, whose elements must all be annotations of the type being
declared:

```
@implicit(@outer.@atomicity, @atomicity(Atomicity.Nonatomic))   // both are @atomicity
@type atomicity(value: Atomicity);
```

**Off an annotation, `.@name` reaches a meta-annotation.** Meta-annotations — `@retention`,
`@target`, `@repeatable` — are declared on the annotation *type*, and an annotation instance
carries no annotations of its own, since there is no syntax for annotating an individual
use. So the left operand can be the annotation type directly:

```
@atomicity.@retention           // the retention of the annotation type @atomicity
@outer.@atomicity.@retention    // the same value, reached via an instance
```

The second form is well-defined but redundant: the instance does no work, because every
`@atomicity` instance yields the same retention. Prefer the direct form.

This is a small level shift — off a type, `.@name` fetches an annotation *attached to* that
type; off an annotation, it fetches a meta-annotation from that annotation's type. The shift
is forced rather than chosen, and reads naturally enough that the operator stays uniform in
use.

Note also that a query rooted at a type, such as `Vector<T>.@atomicity`, is an ordinary
`Expr` and could in principle appear in running code; one rooted at an annotation, such as
`@atomicity.@retention`, is legal only in the annotation-value sublanguage, since a bare
annotation is an `AnnPrimary` and not a `Term`. Until run-time retention exists, both are
compile-time only in practice.

**Presence.** An annotation name may take the existing `.?` suffix, giving a test that is
parallel to Virgil's `T.?(x)` — in both, the *kind* being tested for is on the left and the
subject on the right, matching the language's existing split between retrieval (`x.foo`,
subject on the left) and kind-testing:

```
@atomicity.?(Vector<T>)       // does Vector<T> carry an @atomicity annotation?
```

An absent annotation is **not** null. Absence is its own compile-time state, and it is
deliberately confined to two places: `@implicit` discharges it by taking the first element
of its list that fully resolves, and `.?` observes it. Null would not generalize, since
annotations may be value types, and it would give absence two spellings.

Confining absence is what keeps it cheap. If a first-available operator could appear
anywhere inside a value expression, "unavailable" would have to propagate through arbitrary
compile-time evaluation — `@outer.@atomicity.value + 1` would need an answer when the query
does not resolve, which amounts to threading an option through the whole annotation-value
sublanguage. Restricting it to `@implicit`'s argument list makes the rule local: evaluate
each element in order, skip any that contains an unresolved query, take the first that
resolves. `.?` is the escape hatch for anything that rule does not cover.

This is why the design note's `@or` is **not** part of this proposal — see §11C.

### 3.3 Splicing a computed annotation

A query yields an annotation, but a query is not itself an annotation — it cannot be
written where an annotation goes. `@apply` bridges the two:

```
@apply(Vector<T>.@atomicity)
@apply(@outer.@atomicity)
```

Use sites rarely need fallback logic of their own: because `@implicit` supplies a value
wherever an explicit annotation is absent, a query written at a use site normally resolves.

`@apply` is the second and last reserved annotation name. It takes one annotation-valued
argument and applies it at the position where it appears. This keeps the invariant that
**every annotation begins with `@`**, so no parse ever has to speculatively read a
`TypeRef` that turns out to belong to an annotation; and it avoids re-wrapping a query in
the very annotation type it already yields, which would be a type error rather than merely
verbose — `@atomicity` takes an `Atomicity`, not an `@atomicity`.

### 3.4 Examples

```
@deprecated
@deprecated()
@deprecated("use Foo2 instead")
@deprecated(why = "use Foo2 instead", Date(2026, 8, 1))
@deprecated(Date(2026, 8, 1), "use Foo2 instead")
@target([TargetKind.Class, TargetKind.Variant, TargetKind.Enum])
@clones_type(@atomicity(Atomicity.Atomic))
@implicit(@outer.@atomicity, @atomicity(Atomicity.Nonatomic))
@apply(@outer.@atomicity)
```

Argument binding follows the design note: keyword arguments are bound first, then
positional arguments fill the remaining fields left to right, then defaults apply, and a
field marked `@required` with no value is an error.

---

## 4. Declaring an annotation

```
AnnotationTypeDecl ::= Annotation* ['private'] '@type' Id AnnFields? (';' | AnnBody)
AnnFields          ::= '(' AnnField,* ')'
AnnField           ::= Annotation* Id ':' TypeRef ('=' Expr)?
AnnBody            ::= '{' (['private'] 'def' DefDef)* '}'
```

`'@type'` is `@` glued to the keyword `type`. `AnnBody` permits methods only — no `var`, no
`new` — because an annotation's fields are its parameters. This mirrors
`DefaultCaseMembers` in the existing grammar, a shape the parser already has.

```
AnnotationAliasDecl ::= Annotation* ['private'] '@def' Id '=' Annotation,+ ';'
```

An alias binds a **list** of annotations, so one name can stand for several. Using the
alias is exactly equivalent to writing out its expansion in place, and the alias is legal
only where every annotation in its expansion is — the intersection of their target sets.

Both forms are top-level declarations, and both may carry annotations of their own, which
is how an alias declares the targets it serves when a name is overloaded (§4.1).

```
@target(TargetKind.Declaration)
@type deprecated(@required since: Date, why: string = "");

@type atomicity(value: Atomicity) {
	def atomic_ok() => value != Atomicity.Nonatomic;
	def nonatomic_ok() => value != Atomicity.Atomic;
}

@def atomic    = @atomicity(Atomicity.Atomic);
@def nonatomic = @atomicity(Atomicity.Nonatomic);
@def relaxed   = @atomicity(Atomicity.Relaxed);

@def rw        = @readable, @writable;      // expands to two annotations
```

### 4.1 Overloading by target

An annotation name may be declared **more than once, for disjoint sets of targets**. This
is what lets `@atomic` mean one thing on a container and another on a type use, as the
design note intends:

```
@target(AtomicTargets)
@def atomic = @atomicity(Atomicity.Atomic);   // on containers, code, fields

@target(TargetKind.TypeUse)
@clones_type(@atomicity(Atomicity.Atomic))
@type atomic;                                  // on type uses — a different annotation
```

`@type` and `@def` share one overload set per name: a name may be a `@type` for some
targets and a `@def` alias for others.

Overloading is resolved entirely by position and needs no lookahead, because **every
syntactic position in §6 determines exactly one target kind.** The grammar keeps the
distinctions that matter apart rather than leaving them to inference — `@atomic var x: T`
is a Field annotation and `var x: @atomic T` a TypeUse annotation, at different positions;
likewise `@ann def m() { }` (Method) versus `def m() { @ann { … } }` (Block), and
`@ann case X;` (VariantCase) versus `@ann def m()` (Method) inside the same variant body.

Two constraints follow:

- The target sets of the declarations sharing a name must be **disjoint**; overlapping
  declarations are an error at the point of the second declaration, not at the use.
- A use at a position whose target kind no declaration covers is an error naming the
  target kind, so the diagnostic can say *which* overload was sought.

The reserved names `@file` and `@apply` are not overloadable.

Because nothing about the meta-annotations is grammar-special, the standard-annotations
file declares them the same way:

```
@target(TargetKind.AnnotationType)
@type target(value: TargetKind.set);

@target(TargetKind.AnnotationType)
@type repeatable;

@target(TargetKind.Field)
@type required;

@target(TargetKind.AnnotationType)
@type retention(value: Retention);
```

---

## 5. File and program level

File-level annotations require an explicit marker. `@file` is reserved, and is legal only
as a top-level declaration:

```
FileAnnotation ::= '@file' AnnotationArgs ';'
```

```
@file(@deprecated);
@file(@atomicity(Atomicity.Atomic));
```

A `FileAnnotation` may appear anywhere among the top-level declarations, and may appear
more than once; the arguments accumulate. Each argument must permit `TargetKind.File`.

**A top-level `Annotation+` must be followed by a declaration.** There is no bare
`Annotation+ ';'` form, so a stray or missing semicolon cannot silently retarget an
annotation from the following declaration to the whole file — `@deprecated;` at top level
is a parse error, and `@file(@deprecated) class C { }` is too. This is the whole reason for
reserving the name rather than letting a terminator carry the meaning.

Nothing is lost from the standard-annotations file by reserving `@file`: its semantics is
"apply my arguments to the enclosing compilation unit", which no ordinary `@type`
declaration could express in any case.

Program-level annotations are not source syntax:

```
-@program=<Annotation>
-@file=<filename>=<Annotation>
```

These need no change to option parsing. `Option.v3` treats any argument beginning with `-`
as an option and splits the name from the value at the **first** `=`, so `-@program` and
`-@file` are ordinary option names, and `-@file=Foo.v3=@deprecated` yields the value
`Foo.v3=@deprecated` for the handler to split again. Parentheses in an annotation need
shell quoting.

---

## 6. Where annotations may appear

Supported targets, with the syntax at each:

| Target | Syntax |
|---|---|
| File | `'@file' '(' Annotation,* ')' ';'` at top level |
| AnnotationType | `Annotation* ['private'] '@type' …` |
| Class | `Annotation* ['private'] 'class' …` |
| Component | `Annotation* ['private'] ['thread'] 'component' …`, `Annotation* 'import' …` |
| Variant | `Annotation* ['private'] 'type' …` |
| Enum | `Annotation* ['private'] 'enum' …` |
| VariantCase | `Annotation* 'case' Id …`, `Annotation* 'case' '_' …` |
| EnumCase | `Annotation* Id EnumArgs? ','?` |
| Field | `Annotation* ['private'] ('var' \| 'def' \| 'def var') …` |
| Method | `Annotation* ['private'] 'def' …`, `Annotation* ['private'] 'new' …` |
| Parameter (formal *type* parameter) | `'<' Annotation* Id ,* '>'` |
| TypeUse | `Annotation* TypeRef` |
| Block | `Annotation* BlockStmt` |

Deliberately **not supported**, though designed around — see §10:
Formal (value parameter), Actual, Local, Statement, Expression.

### Worked examples

```
@file(@deprecated);

@target([TargetKind.Class, TargetKind.Variant])
@type cold;

@cold @deprecated("use Foo2") class Foo #unboxed {
	@readonly var x: int;
	@cold def slowPath() { }
	@inline new(x) { }
}

@cold private component Diagnostics { }

type Tree<@hard T> {
	@deprecated case Leaf;
	@cold case Node(l: Tree<T>, r: Tree<T>);
	@cold case _;
}

enum Color {
	@deprecated Red,
	Green,
}

class Vector<T> {
	var size: int;
	var elements: @apply(@outer.@atomicity) Array<T>;
	def get(i: int) -> @atomic T { ... }
}

component Main {
	def run() {
		def v1 = Vector<int>.new();
		def v2 = @atomic Vector<int>.new();
		def v4 = @atomic Vector<@atomic Array<int>>.new();
		@atomic {
			v2.size = 0;
		}
	}
}
```

### Three rules the grammar makes but the eye may not

**A second `(` is never arguments.** Once an annotation's argument list is closed, a
following `(` begins the annotated type or expression, spaced or not — the whitespace rule
of §7.1 governs only the *first* paren after the name:

```
@ann(a)(int, int)      // @ann with argument a, applied to (int, int)
@ann(a) (int, int)     // identical
@apply(q)(int, int)    // likewise for a splice
```

**Function types.** `Annotation*` sits at the head of `TypeRef`, *before* the `->` suffix
loop, so an annotation binds to the whole function type:

```
@atomic int -> int          // annotates (int -> int)
(@atomic int) -> int        // annotates only the argument
```

A one-element tuple is its element type in Virgil, so the parentheses in the second form
are pure grouping and cost nothing.

**Expression position.** In expression position an annotation binds to the immediately
following *term*. When that term is a type or constructor reference, it is a TypeUse
annotation — which is what makes `@atomic Vector<int>.new()` mean "an atomic clone of
`Vector<int>`" rather than anything about the call.

---

## 7. Ambiguity analysis

### 7.1 The one real ambiguity: `@name` followed by `(`

Consider:

```
var p: @atomic (int, int);
```

Two readings are both well-formed under `Annotation ::= '@' Id ArgList?` together with
`AnnotatedType ::= Annotation* TypeRef`:

- `@atomic(int, int)` — an annotation with two arguments, after which the type reference is
  missing; or
- `@atomic` with no arguments, applied to the tuple type `(int, int)`.

This **cannot** be settled by lookahead, however far, nor by trial parsing. `(int, int)` is
simultaneously a well-formed tuple type *and* a well-formed expression list — `int` parses
as an ordinary `VarExpr` — so **both parses succeed**. It requires a rule.

**Rule: `(` glued to the annotation name begins an argument list; `(` separated from it by
whitespace applies the annotation to what follows.**

```
@ann(a, b)      // annotation with two arguments
@ann (a, b)     // @ann applied to the tuple type (a, b)
```

The rule governs only the first paren after the name; see §6 for what a second one means.

This is not a new kind of rule for Virgil. `parseIdentCommon` already scans raw input for
`<`, so `Foo<T>` is a generic reference and `Foo <T>` is not; and `#hint` / `@name` already
forbid an interior space. "An annotation is one tight lexical unit" is a single coherent
convention. It also keeps the `@ann (expr)` expression form available if Expression targets
are added later.

### 7.2 Everywhere else is unambiguous

No *declaration* target can be followed by `(`: each is followed either by a keyword
(`class`, `component`, `thread`, `import`, `type`, `enum`, `def`, `var`, `new`, `case`,
`private`) or by an identifier (enum cases, type parameters). The paren rule is therefore
irrelevant to every declaration target and matters only for TypeUse — and later for
Expression.

- **Block** is safe: `@ann { … }` cannot be read as arguments.
- **`.@name`** is free: `.` followed by `@` is illegal today.
- **Statement position**: `@ann (` reads as an Expression-target annotation and yields a
  clean "not supported" diagnostic rather than a misparse.
- **Rep hints** do not interact. Annotations are prefix, hints are postfix, and the sigils
  differ: `@deprecated class C #unboxed { }` is unambiguous.

### 7.3 Coexistence with the unimplemented `struct` feature

`test/feature/struct.v3` — a `//@seman` test for the reserved-but-unimplemented `struct`
keyword, currently listed in `test/feature/failures.txt` — uses `@` as an **infix**
operator:

```
var x1: ref<S1> = a[S1 @ 0];
```

This is a future claim on `@`, and it can coexist with annotations, because the two occupy
different parser positions: an infix `@` follows a complete term, a prefix `@` starts one.
That is exactly how `-` already serves as both negation and subtraction. The glue rule
reinforces the separation, since `S1 @ 0` has whitespace and a numeric right operand.

**Constraint this places on the `struct` feature if it lands:** `a[S1 @off]` — infix `@`
glued to an identifier — would be indistinguishable from an annotation by lexical form
alone and would have to be resolved positionally. Whoever implements `struct` should either
require whitespace before an infix `@` or rely strictly on the term-position distinction.

---

## 8. Compatibility

Every position this proposal claims is currently a **hard parse error**, verified against
`bin/current/x86-linux/Aeneas`:

| Probe | Current error |
|---|---|
| `@deprecated class C { }` | `ParseError: expected type, variable, or method declaration` |
| `@readonly var x: int;` in a class | `ParseError: invalid start of member declaration` |
| `@cold case Leaf;` in a variant | `ParseError: invalid start of type case declaration` |
| `@deprecated Red,` in an enum | `ParseError: identifier expected` |
| `var x: @atomic Array<int>;` | `ParseError: identifier expected` |
| `@atomic { … }` in a body | `ParseError: invalid start of expression` |
| `return @atomic (1 + 2);` | `ParseError: invalid start of expression` |
| `class C<@hard T> { }` | `ParseError: identifier expected` |
| `return Array<int>.@atomicity;` | `ParseError: member expected` |
| `return Array<int>.@atomicity.value;` | `ParseError: member expected` |
| `return @atomicity.?(Array<int>);` | `ParseError: invalid start of expression` |
| `var e: @apply(@outer.@atomicity) Array<T>;` | `ParseError: identifier expected` |
| `@file(@deprecated);` | `ParseError: expected type, variable, or method declaration` |
| `@type deprecated(why: string = "");` | `ParseError: expected type, variable, or method declaration` |
| `@def atomic = @atomicity(1);` | `ParseError: expected type, variable, or method declaration` |
| `@deprecated;` at top level | `ParseError: expected type, variable, or method declaration` |

`@deprecated;` at top level stays an error under this grammar too, by §5 — a top-level
annotation must be followed by a declaration.

The feature is therefore **purely additive**: no existing program can change meaning.
No `.v3` file in `test/`, `lib/`, `apps/`, `rt/`, `bench/`, or `aeneas/src/` uses `@` in
source position, apart from the aspirational `struct` syntax discussed in §7.3.

Five existing negative parse tests use `@` as their illegal character:

```
test/core/parser/illegal01.v3     @
test/core/parser/fsi16.v3         var x: i@;
test/core/parser/expr40.v3        var y = @;
test/enums/parser/params14.v3     enum E(@) { A }
test/descriptor/parser/desc08.v3  class C descriptor @ { }
```

All five continue to be `ParseError` under this grammar, since in each case `@` is followed
by something that is not an identifier, or sits in a value-parameter list where annotations
are not supported. They will keep passing: `SemanTestCase.matches` compares only the error
*kind*, so the `@ line:col` in a `//@parse = ParseError @ 2:1` header is documentation and
a column shift is harmless.

---

## 9. Implementation map

Recorded here so it is ready when implementation begins; nothing below is done.

The model to copy is `parseRepHints` (`aeneas/src/vst/Parser.v3:318`), which already handles
the bare / `(exprs)` / `<types>` shapes and uses `p.eat1()` after `#` — deliberately not
`advance1()` — to forbid an interior space.

| Production | Parser site |
|---|---|
| File, AnnotationType, and dispatch to all top-level decls | `parseToplevelDecl` :127 |
| Class | `parseClass` :183 |
| Component | `parseComponent` :213 |
| Variant | `parseVariant` :220 |
| Enum | `parseEnum` :464 |
| VariantCase | `parseVariantCase` :375 |
| EnumCase | `parseEnumCase` :487 |
| Field, Method, Constructor | `parseMember` :533 |
| Parameter (type param) | `parseTypeParam` :663 |
| TypeUse | `parseTypeRef` :631 and `parseTerm` :947 |
| Block | `parseStmt` :667 |
| `T.@ann` | `addMemberSuffix` :1183 — add an `'@'` arm beside the existing `!`/`?`/`~`/`[]` arms |
| `@ann.?(x)` | no new code — the existing `.?` arm at :1189 applies once an annotation name can be a primary |

Notes for the implementer:

- **`parseAnnotations` must not consume `@` + keyword.** Its loop condition needs to peek
  the identifier after `@` and stop if it is a keyword, leaving `@type` / `@def` for the
  caller. The identifier bytes can be hashed against `Keywords` from the raw input without
  advancing.
- **The two reserved names are recognized after parsing, not during.** `@file` and `@apply`
  parse as ordinary annotations; the top-level dispatcher then checks whether the single
  annotation it collected is named `file` before accepting a `;`, and the verifier
  interprets `@apply`. Nothing special is needed in the annotation scanner itself.
- **Restructure the dispatch functions rather than threading a parameter everywhere.**
  `parseToplevelDecl` and `parseMember` should parse annotations first and then fall into
  the existing `match (p.curByte)`, so `@ann private class C` works with no special case.
  Annotations can then be attached after the fact, the way `parseClass` already does at
  :196 (`decl.repHints = repHints;`).
- **Storage mostly exists.** `repHints` slots on `VstCompound` (`Vst.v3:123`), `VstMember`
  (`:317`), and `VarDecl` (`:641`) cover every compound, every member kind, and
  locals/params. Two targets have no home yet:
  - **Type parameters** are represented directly as `TypeParamType` (`types/Type.v3:80`),
    a *type*, with no AST decl node. Annotations there need a new field or a new node.
  - **`TypeRef`** (`Vst.v3:548`) has no slot, and its `binding` field memoizes the resolved
    `Type`. Since `@clones_type` makes an annotated type use a *distinct* type, the
    interaction between annotations and `binding` is the deep part of the design and should
    be settled before TypeUse is implemented.
- **Gate it** as `CLOptions.ANNOTATIONS` in the `lang:` family, wrapped in
  `if(Debug.UNSTABLE, …)` like `lang:open-types`, plumbed to a `p.enableAnnotations` field
  on `ParserState` and read in `parseFile` (:105-108).
- **Printing** goes in `VstPrinter.v3` alongside `printRepHint` (:134).
- **No test-harness collision.** `//@execute` and friends live in comments read by a
  separate pre-pass (`test/Regression.v3:103`) with its own `ParserState`; they are
  invisible to `Parser.parseFile`.

---

## 10. Not supported, and what they would look like

These are designed around rather than designed in, per the design note's judgment that
statement- and expression-level annotations carry the greatest internal burden and the most
friction between the user's AST-shaped view and the compiler's SSA-shaped one.

| Target | Would be | Note |
|---|---|---|
| Local | `@atomic var v = …;` in a body | Cheapest later addition — same shape as a field, and `VarDecl` already has a metadata slot. |
| Formal | `def m(@nonnull a: Array<int>)`, `def m(@readonly this, i: int)` | Grammatically free; the receiver form needs an explicit `this` parameter. |
| Actual | `f(@relaxed x)` | Conflicts with nothing, but has no use case yet. |
| Statement | `@atomic x = 1;` | Wrapping the statement in `{ }` and using a Block annotation covers this. |
| Expression | `f(@relaxed (a + b))` | Depends on the paren rule in §7.1, which is why that rule was chosen to keep the door open. |

In statement position, an annotation must currently be followed by `{`. Anything else
should produce a specific diagnostic naming the unsupported target rather than a generic
parse error.

---

## 11. Decisions taken here, and what remains open

**A. `@def` binds a list.** `@def rw = @readable, @writable;`. Settled in favour of the
list form, which is at least as useful and costs nothing: `@clones_type` already takes a
list of annotations, so lists were a live concept regardless. See §4.

**B. Annotation names are overloadable by target.** Settled in favour of allowing it, as
the design note intends with `@atomic`. This is sound rather than merely tolerated, because
every syntactic position determines exactly one target kind, so resolution is by position
and requires no inference. Declarations sharing a name must have disjoint target sets. See
§4.1.

**C. `@or` is dropped in favour of a list-valued `@implicit`.** `@implicit(a, b, c)` takes
the first element that fully resolves, replacing `@implicit(@or(a, b))`.

The motivation is not economy but containment. Absence is its own compile-time state
(§3.2), and that is affordable only while it arises and is discharged in one place. A
general first-available operator usable anywhere inside a value expression would force
"unavailable" to propagate through arbitrary compile-time evaluation — `@outer.@atomicity.value + 1`
would need a meaning when the query does not resolve — which amounts to threading an option
through the entire annotation-value sublanguage. `@implicit`'s list keeps the rule local,
and `.?` remains the explicit escape hatch.

What this gives up: `@or` falls back at *field* granularity, `@implicit` only over whole
annotations. They coincide for a single-field annotation such as `@atomicity`. For a
multi-field annotation with only some fields derived, `@or` would allow
`@foo(@or(@outer.@foo.a, 0), 0)` where the list form requires enumerating whole
alternatives. No current use case needs this.

Nothing is foreclosed. `@or` is only an annotation name, so reinstating it later requires
no grammar change and breaks nothing — and the asymmetry favours waiting, since a form can
always be added but rarely removed.

**D. Still open: a root `Annotation` type.** Writing the standard annotations file (§12)
turned up the one genuine gap in this design. `@implicit` and `@clones_type` both need a
field that *holds an annotation*, and the language has no type for that. The design note
sketches it as `A@`, the root of a compiler-generated hierarchy; it needs to become a real
built-in type name, written `Annotation` provisionally in `lib/annotations/Standard.v3`.
Nothing else in the proposal depends on it, and it is not needed until the verifier stage.

**E. Chaining `.@` off an annotation is meaningful, and redundant.** See §3.2 — it reaches
a meta-annotation of the annotation's *type*, so the direct form `@atomicity.@retention` is
preferred over `@outer.@atomicity.@retention`. The grammar admits both.

---

## 12. The standard annotations file

Drafted, as the first end-to-end test of this grammar, in two files:

| File | Contents | Parses under |
|---|---|---|
| `lib/annotations/TargetKind.v3` | `enum TargetKind`, `enum Retention`, `component TargetKinds` (the `Declaration` / `Container` / `Code` / `Supported` groupings) | **any** compiler, verified against both `bin/current` and `bin/stable` |
| `lib/annotations/Standard.v3` | the six meta-annotations: `@target`, `@repeatable`, `@required`, `@retention`, `@implicit`, `@clones_type` | only a compiler with `-lang:annotations` |

The split exists because of bootstrap. The first stage of `make bootstrap` compiles
`aeneas/src/` with `bin/stable/<host>/Aeneas`, which cannot parse annotation syntax.
Keeping everything that needs no `@` in a separate file means no compiler is ever handed
syntax it cannot read, and a stale compiler fed the annotated half fails in a file
containing nothing but annotation declarations, which is self-explanatory.

Neither file may be added to `aeneas/DEPS`, nor globbed unconditionally by a wrapper script.

### How it is loaded

A `-lang.annotation-files=<path*>` option, prepended to the program's file list in
`Aeneas.makeProgram` exactly as `-rt.files=` is at `Aeneas.v3:64-71`, and applied only when
`-lang:annotations` is on. The platform wrappers supply the path the way
`bin/v3c-x86-64-linux` already computes `$RT`:

```
LIB=$(cd $BIN/../lib && pwd)
... -lang.annotation-files="$LIB/annotations/*.v3"
```

**The compiler must be the one to decide, not a wrapper.** Wrapper scripts honour `V3C` /
`AENEAS_TEST`, and `test/all.bash` supports `AENEAS_TEST=stable`, so any unconditional
wrapper glob eventually hands the stable compiler a file it cannot parse. Gating inside the
compiler on its own `-lang:annotations` flag avoids this: the stable compiler does not have
that option at all, so an attempt to use it fails immediately with "unknown option" rather
than with a confusing parse error inside a library file.

The compiler cannot find the files by itself. `Aeneas.main(args)` receives no `argv[0]`, and
there is no `getenv` anywhere in `aeneas/src/` — so there is no install-root discovery to
build on, and the path must come from the command line.

Sequencing note: the parser stage does **not** need these files. Parsing is syntax-only, and
the standard annotations first matter at verification, when `@target` and friends must be
resolved. Parser tests can be plain `//@parse` cases with no library at all.

### `FEATURE_ANNOTATIONS`

Worth adding to `CiRuntime.lookupMember` (`CiRuntime.v3:109-115`) returning
`CLOptions.ANNOTATIONS.val`, alongside the existing `FEATURE_*` constants — it lets Virgil
code branch on whether annotations are enabled, and older compilers answer `false`
automatically via the catch-all at `:115`.

It is **not** the inclusion mechanism, and cannot be. `CiRuntime.FEATURE_X` resolves to a
`LookupResult.Const` during *verification*, long after the file containing it has parsed. A
value cannot gate whether syntax is readable.

### What the file does not declare

- `@file` and `@apply` are reserved by the grammar (§5, §3.3). The compiler knows them
  structurally, so declaring them would be misleading.
- `@this` and `@outer` are not annotations. They are target designators in the
  annotation-value sublanguage, valid only to the left of a `.@name` query, and no `@type`
  declaration could describe them.

### Corrections to the design note that writing the file forced

- **`@target` needs no array form.** Enum sets and `@repeatable` cover every case:
  `@target(A | B)`, `@target(A) @target(B)`, and `@target(TargetKinds.Container)`. The
  note's `@target([TargetKind.Class, ...])` bracket spelling is unnecessary.
- **`@required` targets an annotation *field*, which is not a class field.** `TargetKind`
  therefore has a distinct `AnnotationField` case, matching the note's separate `AMF@`
  category.
- **The note's `def AtomicTargets = [TargetKind.Container, TargetKind.Code, TargetKind.Field]`
  does not typecheck.** `Container` and `Code` are enum *sets*, not enum cases; it must be
  `TargetKinds.Container | TargetKinds.Code | TargetKind.Field`.
- **`@implicit` and `@clones_type` need an annotation-valued field type**, which the
  language lacks. See §11D — this is the one real gap the exercise found.
