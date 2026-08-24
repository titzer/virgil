# Virgil Annotations — Parser and AST Plan

Status: **implemented** in `6fa363f16`. Kept as the record of why the parser is shaped the
way it is; §10's handoff list is now carried out in `doc/annotations-verifier.md`.

Two things changed during implementation. `VstAnnotation.decl` became `.binding` (plus
`.target`, `.boundArgs`, `.values`, `.file` as later stages needed them), since a use may
resolve to a `@def` alias as well as a `@type`. And annotation fields are `VarDecl` rather
than `ParamDecl`: `ParamDecl`'s constructor hardcodes a null initializer, so it cannot carry
a default value.

Scope: stage 1 of the annotation facility — parse the syntax fixed in
`doc/annotations-syntax.md`, build AST for it, print it, and test it. Annotations are
stored on the nodes they attach to and nothing more: **no name resolution, no target
checking, no constant evaluation, no IR propagation.** Those belong to the verifier stage,
whose handoff points are listed in §10.

Stage 1 has no dependency on `lib/annotations/`. Parsing is syntax-only; the standard
annotations first matter when `@target` must be resolved. Parser tests are plain `//@parse`
cases against no library.

The model throughout is `parseRepHints` (`aeneas/src/vst/Parser.v3:318`) — the existing
attribute-like construct, which already handles bare / `(exprs)` / `<types>` forms and uses
`p.eat1()` after `#`, deliberately not `advance1()`, to forbid an interior space.

---

## 1. New AST nodes

In `aeneas/src/vst/Vst.v3`, beside `VstRepHint` (`:469`):

```
// An applied annotation: @name, @name(args)
class VstAnnotation(at: FilePoint, name: Token, args: VstList<VstAnnArg>) {
	var decl: VstAnnotationDecl;      // resolved by the verifier; null after parsing
	def range() -> FileRange { ... }  // from `at` through args, or the name token
}

// One argument. `name` is null for the positional form.
class VstAnnArg(name: Token, value: Expr) { }

// An annotation declaration: @type name(fields) { methods }
class VstAnnotationDecl extends Decl {
	def isPrivate: bool;
	def annotations: VstList<VstAnnotation>;   // meta-annotations on this declaration
	def fields: VstList<ParamDecl>;
	def members: List<VstMember>;              // methods only
}

// An alias: @def name = ann, ann, ...;
class VstAnnotationAlias extends Decl {
	def isPrivate: bool;
	def annotations: VstList<VstAnnotation>;
	def expansion: VstList<VstAnnotation>;
}
```

**A class, not a variant.** `VstRepHint` is a `type` with one case per known hint, which is
right for a closed set the compiler enumerates. Annotations are open and user-declared, and
need a mutable `decl` slot for later resolution, so a class fits.

**`VstAnnotationDecl` extends `Decl`, not `VstCompound`.** An annotation type does have a
compound's shape — a name, parameters that become fields, and methods — and reusing
`VstCompound` would inherit `memberMap`, `typeEnv`, and the verifier plumbing. But
`VstCompound` requires a `typeCon`, a `declType`, and a `Kind`, and `Kind`
(`types/Type.v3:5`) is the type-system-wide kind enum: 48 files reference it across 74
`match` sites. Adding `Kind.ANNOTATION` is a type-system change, not a parser change, and
it is coupled to the design note's "annotations are compiler-generated ADTs" representation,
which is undecided. Stage 1 should record the syntax and leave that open. Promoting
`VstAnnotationDecl` to a `VstCompound` later is a contained change.

### Two new expression nodes

Needed because an annotation may appear as a *value* (`@clones_type(@atomic)`), and because
annotations may prefix a term in expression position (`@atomic Vector<int>.new()`):

```
class AnnotationExpr(ann: VstAnnotation) extends Expr {
	def accept<E, R>(v: VstVisitor<E, R>, env: E) -> R { return v.visitAnnotation(this, env); }
	def range() -> FileRange { return ann.range(); }
}
class AnnotatedExpr(anns: VstList<VstAnnotation>, expr: Expr) extends Expr {
	def accept<E, R>(v: VstVisitor<E, R>, env: E) -> R { return v.visitAnnotated(this, env); }
	def range() -> FileRange { return FileRanges.add(anns.range(), FileRanges.ofExpr(expr)); }
}
```

`Expr.accept` is abstract over `VstVisitor` (`Vst.v3:507`), so each new subclass adds a
method to the base plus its three implementors — `VstPrinter.v3`, `VstSsaGen.v3`,
`Verifier.v3`. Eight small edits total. In stage 1 the `VstSsaGen` and `Verifier` cases
should fail loudly: nothing should reach SSA yet.

Wrapping, rather than making `VstAnnotation` itself an `Expr`, keeps `exactType` /
`implicitType` off the node that hangs on declarations, where they would be meaningless.

---

## 2. Storage on existing nodes

Add `var annotations: VstList<VstAnnotation>;` to each:

| Node | Location | Covers |
|---|---|---|
| `VstCompound` | `Vst.v3:106` | class, component, variant, enum, layout, packing |
| `VstMember` | `Vst.v3:312` | every member kind, incl. `VstEnumCase` and `VstCaseMember` |
| `VarDecl` | `Vst.v3:635` | locals and, via `ParamDecl`, parameters |
| `TypeRef` | `Vst.v3:548` | TypeUse |
| `BlockStmt` | `Vst.v3:672` | Block |
| `TypeParamType` | `types/Type.v3:80` | formal type parameters |

Each sits directly beside an existing `repHints` slot except the last three.

`VstFile` (`Vst.v3:19`) gets `def annotations = Vector<VstAnnotation>.new();`, accumulated
from `@file(...)`. Note `VstFile` is not a `Decl` and has no `Token`, so positions must come
from each annotation's own `at`.

**On `TypeParamType`.** Hanging syntax on a `Type` looks wrong, but is safe here:
`TypeUtil.newTypeParam` (`TypeUtil.v3:67`) allocates a fresh object per declaration, with
`UID.next++` and its own `TypeCon`, so no two declarations share one. The node already
carries a `token`, so it is no less syntactic than before. The clean alternative —
introducing a real `TypeParamDecl` AST node — is a large change for a single target and
should be weighed on its own, not smuggled in here.

**On `TypeRef`.** `TypeRef.binding` memoizes the resolved `Type` (`Verifier.v3:997`). Since
`@clones_type` makes an annotated type use a *distinct* type, annotations and `binding`
interact. Stage 1 only stores the list; §10 records the problem.

---

## 3. Attachment strategy

Prefix annotations must reach a construct parsed by a function that has already been
entered. There are three ways to do it, and the codebase already supplies the two good ones.

### Members: diff the list

`parseMember` (`:533`) receives `prev` and returns the extended list, so it can walk what
was added. This is the idiom `parseExport` already uses at `:426`:

```
def parseMember(p: ParserState, prev: List<VstMember>, allowImportName: bool) -> List<VstMember> {
	var anns = if(p.enableAnnotations, parseAnnotations(p));
	var isPrivate = optKeyword(p, "private") != null;
	...                                        // existing match (p.curByte) dispatch
	for (l = nlist; l != prev; l = l.tail) l.head.annotations = anns;
	return nlist;
}
```

This needs **no signature changes inside `VarDefParser`**, and it gets `@ann def a, b, c;`
right for free: `parseFieldSuffix` (`:1624`) produces three `VstField`s from one call, and
all three receive the annotation.

The same shape works for `parseVariantCase` (`:375`), which also takes `prev` and returns a
list.

### Top level: pass a parameter

Top-level declarations go into `file.classes` / `file.components` / … vectors rather than a
cons list, so there is nothing to diff. Add an `anns` parameter to `parseClass` (`:183`),
`parseComponent` (`:213`), `parseVariant` (`:220`), `parseEnum` (`:464`), `parseLayout`
(`:494`), `parsePacking` (`:300`), and `parseExport` (`:418`). Each already ends with
`decl.repHints = repHints;`, so it is one more line in the same place.

### Not recommended: a pending-annotation buffer on `ParserState`

Collecting annotations into a mutable field that later constructs "look back" at is
tempting, but it is fragile across error recovery — `parseList` bails on non-progress
(`:1268`) and `p.error` suppresses after `maxErrors` (`ParserState.v3:161`) — and it has no
answer for nesting, since a type-use annotation can appear inside a member annotation's own
argument list. The two idioms above make it unnecessary.

---

## 4. New parser functions

```
def parseAnnotations(p: ParserState) -> VstList<VstAnnotation> {
	if (p.curByte != '@') return null;
	var start = p.point();
	var list: List<VstAnnotation>;
	while (p.curByte == '@') {
		if (isKeywordAfterAt(p)) break;     // '@type' / '@def' belong to the caller
		list = List.new(parseAnnotation(p), list);
	}
	if (list == null) return null;
	return VstList.new(p.end(start), Lists.reverse(list));
}

def parseAnnotation(p: ParserState) -> VstAnnotation {
	var at = p.point();
	p.eat1();                                          // '@', without skipping whitespace
	if (!Char.isIdentStart(p.curByte)) { p.error("annotation name expected"); ... }
	var q = p.star(0, Char.isIdentMiddle);             // stops at '<'
	var glued = q < p.input.length && p.input[q] == '(';   // BEFORE extractIdent
	var id = extractIdent<void>(p, q);
	var args = if(glued, parseList(0, p, '(', COMMA, ')', parseAnnArg));
	return VstAnnotation.new(at, id.name, args);
}

def parseAnnArg(p: ParserState) -> VstAnnArg {
	var e = if(p.curByte == '@', parseAnnValueFromAnnotation(p), parseExpr(p));
	if (AssignExpr.?(e)) {                             // keyword form: id = value
		var a = AssignExpr.!(e);
		if (a.infix == null && isBareVar(a.target)) {
			return VstAnnArg.new(VarExpr.!(a.target).ident.name, a.expr);
		}
	}
	return VstAnnArg.new(null, e);
}

def parseAnnValueFromAnnotation(p: ParserState) -> Expr {
	var e: Expr = AnnotationExpr.new(parseAnnotation(p));
	return addBinOpSuffixes(p, addTermSuffixes(p, e));
}
```

`isKeywordAfterAt` scans the identifier bytes from `p.curPos + 1` and hashes them against
`Keywords` (`Parser.v3:85`) without advancing the cursor.

`isBareVar` tests for a `VarExpr` with a null receiver `expr` and null `ident.params` — so
`x = 1` is a keyword argument but `a.b = 1` and `f<T> = 1` are not.

Reusing `addTermSuffixes` and `addBinOpSuffixes` is what makes queries free: `@outer.@a`,
`@outer.@a.value`, `@a.?(T)`, and `@outer.@a.value == Atomicity.Atomic` all fall out of the
existing suffix machinery with no new parsing code, once `addMemberSuffix` learns `.@name`.

---

## 5. Three things that will bite

**Capture `glued` before `extractIdent`.** `extractIdent` advances the cursor *and skips
whitespace* (`ParserState.advance` → `skipFunc`). Testing `p.curByte == '('` after it cannot
distinguish `@ann(x)` from `@ann (x)`, silently reintroducing the ambiguity that the
whitespace rule exists to resolve (`doc/annotations-syntax.md` §7.1). Read the raw input at
offset `q` first. `parseRepHints` does *not* do this — `#label (e)` and `#label(e)` are the
same today — so it cannot be copied verbatim here.

**Do not use `parseIdentCommon` for the name.** It scans for `<` and would take `@ann<T>` as
a parameterized name (`:1320-1338`). Annotation names take no type arguments, so scan with
`p.star(0, Char.isIdentMiddle)`, which stops at `<`. This is the same reason `parseRepHints`
hand-rolls its scan, noted in its own `// XXX: ugly difference with parseIdent` at `:326`.

**`parseAnnotations` must not consume `@` + keyword.** `@target(...) @type foo;` requires the
loop to stop at `@type` and leave it for the caller, so the keyword test has to happen
before any cursor movement.

---

## 6. Hook points

| Target | Function | Change |
|---|---|---|
| top-level decls, `@type`, `@def`, `@file` | `parseToplevelDecl` :127 | parse annotations, then branch three ways: `@` → declaration form; `;` → `@file(...)`; else fall into the existing `match (p.curByte)` with `anns` threaded in |
| Field, Method, Constructor | `parseMember` :533 | list-diff (§3) |
| VariantCase | `parseVariantCase` :375 | list-diff |
| EnumCase | `parseEnumCase` :487 | parse at top, assign to the returned `VstEnumCase` |
| Parameter | `parseTypeParam` :663 | parse at top, assign to the returned `TypeParamType` |
| TypeUse (types) | `parseTypeRef` :631 | parse at top; assign **after** the `->` suffix loop, so the annotation binds the whole function type |
| TypeUse (expressions) | `parseTerm` :947 | `'@'` arm → `AnnotatedExpr.new(anns, parseTerm(p))` |
| Block | `parseStmt` :667 | `'@'` arm → require `{`; anything else is a specific "annotations are not supported on this target" diagnostic, naming the target kind |
| `.@name` | `addMemberSuffix` :1183 | new `'@'` arm |

For `.@name`, build a `VarExpr` whose ident token image includes the `@`, matching how the
existing arms store `~`, `!`, `?`, `[]`, and `[]=` as the ident image (`:1189-1220`).
Identifiers cannot contain `@`, so this cannot collide with a real member name.

`parseToplevelDecl` currently returns `false` on failure and `parseFile` (`:113`) breaks out
of the whole file on a false return, so the new arms must keep that contract.

---

## 7. Printing

`VstPrinter.v3` gets a `printAnnotations` beside `printRepHint` (`:134`), called from the
same places the rep-hint printer already is (`:33`, `:72`, `:228`, `:445`) plus the new
sites. Needed for `-print-vst` to be useful while developing, and it is the cheapest way to
eyeball that attachment landed on the right node.

---

## 8. Gating

`CLOptions.ANNOTATIONS` in the `lang:` family, wrapped in `if(Debug.UNSTABLE, …)` exactly
like `lang:open-types` (`CLOptions.v3:34`), read once in `parseFile` (`:105-108`) into a new
`ParserState.enableAnnotations` field (`ParserState.v3:22-25`).

Every hook must test the flag. With it off, `@` must remain the parse error it is today —
`doc/annotations-syntax.md` §8 records the sixteen current error messages, which double as
the expected output for off-by-default regression tests.

Also add `FEATURE_ANNOTATIONS` to `CiRuntime.lookupMember` (`CiRuntime.v3:109-115`) returning
`CLOptions.ANNOTATIONS.val`. It is not needed by the parser, but it costs one line and older
compilers answer `false` automatically through the catch-all at `:115`.

---

## 9. Tests

A new `test/annotations/parser/` suite of `//@parse` cases, following `test/core/parser/`.
Positive cases for every row of §6; negative cases for at least:

- `@ deprecated` and `@/*x*/deprecated` — the glue rule
- `@ann<T>` — names take no type arguments
- `@deprecated;` at top level — a top-level annotation must be followed by a declaration
- `@file(@x) class C { }` — `@file` must be followed by `;`
- `@ann` at a position with no supported target
- annotations used with the flag off

Because `SemanTestCase.matches` (`aeneas/src/test/Regression.v3:218`) compares only the error *kind*,
`//@parse = ParseError @ l:c` positions are documentation and need not be exact.

Two behaviours to pin down with tests specifically, since they are the ones most likely to
regress silently:

- `@ann(a, b)` versus `@ann (a, b)` producing different trees
- `@ann def a, b, c;` attaching the annotation to all three fields

---

## 10. Deliberately out of scope, and handed to the verifier stage

- Resolving `@name` to a `VstAnnotationDecl`, and the overload-by-target rule
  (`doc/annotations-syntax.md` §4.1).
- Checking a use against its declaration's `@target`, and reporting the target kind sought.
- Binding arguments: keyword first, then positional, then defaults, then `@required`
  (§3.4). Note there is no general constant evaluator at VST level today — the closest
  existing practice is literals-only, as in `tryUnboxPositiveInt` (`Verifier.v3:2742`) and
  the match-pattern extraction at `Verifier.v3:1490-1515`.
- Loading `lib/annotations/` via `-lang.annotation-files=` (`doc/annotations-syntax.md` §12).
- The root `Annotation` type that `@implicit` and `@clones_type` need (§11D) — the one known
  gap in the design.
- `TypeRef.binding` versus `@clones_type`: an annotated type use is a *distinct* type, but
  `binding` memoizes one resolved `Type`. This is the deepest unknown and should be settled
  before TypeUse annotations do anything semantic.
- Whether `VstAnnotationDecl` becomes a `VstCompound` with a new `Kind` (§1).
- Any IR propagation. `IrMember.source` (`Ir.v3:105`, `:123`) already points back at the VST
  declaration, so later phases can read annotations without copying them — `VstIr.addRepHintFacts`
  (`VstIr.v3:207`) is the model if copying turns out to be wanted.
