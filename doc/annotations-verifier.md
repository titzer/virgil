# Virgil Annotations — Verifier Plan

Status: **stage 2 is complete**; see §10 for the steps, their commits, and the two
ordering corrections made along the way. The sections below describe the design as built.
Stage 3 — `@implicit` propagation, `@clones_type` and type cloning, retention, annotation
methods, IR propagation — remains, and is scoped in §9.

Scope: stage 2 — give the parsed annotations meaning. Desugar annotation declarations into
real types, resolve each `@name` to its declaration, check it against the target it is
attached to, bind and type-check its arguments, and evaluate them to compile-time values.
Everything downstream — `@implicit` propagation, `@clones_type` and type cloning, retention,
IR propagation — is stage 3 and is listed in §9.

Stage 1 (`doc/annotations-parser.md`, commit `6fa363f16`) parses and stores; it resolves
nothing. Its `AnnotationExpr` stub, which reported `"annotations are parsed but not yet
verified"`, is gone: an annotation used as a value now has the type of its synthesized
variant. `AnnotatedExpr` still reports, since annotations on a type use have no semantics
until `@clones_type` (stage 3).

Syntax and semantics settled so far are in `doc/annotations-syntax.md`; the standard
annotations are drafted in `lib/annotations/`.

---

## 1. What the parser leaves behind

| Where | Slot | Reached from |
|---|---|---|
| `VstFile.annotations` | `Vector<VstAnnotation>` | `@file(...)` |
| `VstFile.annotationDecls` / `.annotationAliases` | vectors | `@type` / `@def` |
| `VstCompound.annotations` | `VstList<VstAnnotation>` | class, component, variant, enum, layout, packing |
| `VstMember.annotations` | " | every member kind, incl. enum and variant cases |
| `VarDecl.annotations` | " | locals, parameters, annotation fields |
| `TypeRef.annotations` | " | TypeUse |
| `BlockStmt.annotations` | " | Block |
| `TypeParamType.annotations` | " | formal type parameters |

`VstAnnotation.binding` and `.target` are the mutable slots stage 2 fills in. `binding` is
an `AnnotationBinding`, not a `VstAnnotationDecl`, because a use may resolve to a `@def`
alias as well as a `@type`; its `None` case makes "unresolved" the default.

---

## 2. Annotation types are desugared into open variants

**Decision: each `@type foo` becomes a synthesized variant `@foo`, a subtype of a
synthesized open root `@Annotation`.** No type-system change is needed, because variants
already answer every representation question, and unreachable synthesized variants cost
nothing in a whole-program compiler.

Implemented in `aeneas/src/vst/AnnotationDesugaring.v3`, run from `Compiler.parse`.

This is what `doc/ideas/Annotations.txt` already sketches, in the language's own syntax:

```
type A@ { }                                              // root of the hierarchy
type AM@ extends A@ { }                                  // meta-annotation root
type AM@target(value: TargetKind.set) extends AM@ { }
type A@deprecated(why: string, date: Date) { }
```

`extends` on a `type` is the open-variant feature, so the note is describing exactly this.
The note spells the names `A@…`; as built they are `@Annotation` and `@name`, for the
reason in "Naming" below. The structure is the note's.

The machinery exists. `VariantDesugaring` (`Vst.v3:272`) already synthesizes `VstClass`es
with `kind = Kind.VARIANT`, `isSynthetic = true`, and a `fullName` distinct from the
declared token — `synthesizeTopLevelClass` (`:286`) and `synthesizeVariantCaseMember`
(`:299`). Annotation desugaring is the same shape.

What this buys, all for free: annotation instances are ordinary variant values, so `Val`,
type checking, subtyping, field defaults, and `Eval.doOp` need no new code; and
`@type implicit(value: Annotation)` is an ordinary field declaration whose type resolves to
the root.

### Naming keeps them out of the ordinary namespace

Every synthesized name carries a `@`, which cannot appear in an identifier, so a user can
neither declare nor reference one, and the annotation namespace stays separate from the type
namespace as `doc/annotations-syntax.md` §2 requires. The name is only a string key in the
type environment, so nothing needs to parse it, and it reads clearly in diagnostics.

That applies to the root as much as to the subtypes. Naming it plain `Annotation` was tried
and rejected: it occupied an attractive identifier program-wide, and a user's own
`class Annotation` then collided with a diagnostic pointing at the synthetic `<annotations>`
file they never wrote.

So that `lib/annotations/Standard.v3` can still say what it means, a bare `Annotation` in an
**annotation field type** is rewritten to `@Annotation` during desugaring, nested positions
included. Elsewhere the name means nothing special and a user may define their own — in
which case an annotation field written `value: Annotation` still means the root.

Each name serves as the token image **and** as `fullName`, which must agree: `TypeEnv.add`
keys on `typeCon.name`, which comes from `fullName` (`V3Class.v3:10`), while the duplicate
check in `bindTypeCon` (`Verifier.v3:727`) looks up the token image.

### Where the root comes from

The root must exist exactly once program-wide, but `@type` declarations are spread across
files, so it cannot be synthesized per file. Synthesize it **before `buildFile`**, into a
synthetic `VstFile` prepended to `prog.vst.files`, and have each `@type`'s desugaring
reference it by name. Declaring it in `lib/annotations/Standard.v3` instead is not an
option, since `@Annotation` is unwriteable.

A parameterless annotation must desugar with an explicit **empty** parameter list: a variant
declared without one is a constructor function rather than a value, so `@type repeatable`
becomes `type @repeatable()` and is built as `@repeatable()`.

The root needs a `case _`, because open-variant subtypes require one.

### Risks, all since retired

All three risks recorded here before implementation were settled by measurement in 2a.1:

- ~~Annotations depend on `-lang:open-types`.~~ They do not. Both gates (`Parser.v3:322`
  and `:555`) are purely syntactic and the verifier's own checks are ungated, so desugaring
  after parsing bypasses them.
- ~~The open-variant machinery has only been driven by parsed hierarchies.~~ It tolerates
  programmatic construction: `resolveSuperClass` establishes the `extends` relation and
  `assignVariantTagsIfRoot` runs. A root without `case _` would have failed at
  `Verifier.v3:655`.
- ~~The synthesized types might become reachable.~~ They do not. The same program compiled
  with and without three annotation declarations differs by exactly one byte — the source
  filename in the source tables.

### Annotation methods are out of scope

`def atomic_ok() => value != Atomicity.Nonatomic;` is user code that the *compiler* would
have to run. No representation choice makes that cheap — Virgil's interpreter makes it
reachable eventually, but stage 2 should type-check such methods without being able to
invoke them. Fields are what has to work.

---

## 3. Pass 1 — build the annotation namespace

Annotation names form **one program-wide namespace**, separate from types and values, with
`private` scoping a declaration to its file exactly as for a class.

Add `annotationDecls` and `annotationAliases` vectors to `VstModule` (`Vst.v3:5`) alongside
`classes` / `components` / …, and populate them in `buildFile` (`Verifier.v3:65`), which
already does this for every other declaration kind.

Because names are **overloadable by disjoint target sets** (`doc/annotations-syntax.md`
§4.1), the map is name → *list* of declarations:

```
class AnnotationEnv {
	def map = Strings.newMap<List<AnnotationBinding>>();
	def lookup(name: string, file: VstFile) -> List<AnnotationBinding>;
}
type AnnotationBinding {
	case None;                              // unresolved; the default
	case Decl(d: VstAnnotationDecl);
	case Alias(a: VstAnnotationAlias);
}
```

Built in `aeneas/src/vst/AnnotationEnv.v3`. `lookup` filters by file so a `private`
declaration is visible only where it was declared, and returns the whole list: selecting
among overloads needs the target kind, so the resolver records the candidates and
`AnnotationChecker` selects once `@target` can be evaluated.

Checks here:

- Declarations sharing a name must have **disjoint** target sets; report at the second
  declaration, not at a use. Checked in two places, because the two halves become
  decidable at different times: the case where either side *omits* `@target` needs no
  evaluation, since the annotation is then legal everywhere and necessarily overlaps, and
  is caught here; the general case is caught by `AnnotationChecker` once `@target` can be
  evaluated.
- `@type` and `@def` share one overload set per name.
- `@file` and `@apply` may not be declared.
- A `@def` expansion resolves to other annotations; detect cycles rather than recursing.

**This pass must run before any `resolveType` call**, per §5. `buildFile` is the first pass
in `Verifier.verify()` (`:26`) and the first `resolveType` is in
`resolveSuperClassAndDescriptorInfo` (`:27`), so it slots between them.

**Self-reference is fine.** `Standard.v3` annotates `@type target` with `@target` itself.
Virgil is whole-program and order-insensitive, so building the whole namespace before
resolving anything makes this well-formed — as Java's `@Target` is itself `@Target`. The
only requirement is that this pass does no resolution.

---

## 4. Pass 2 — resolution

Implemented in `aeneas/src/vst/AnnotationResolver.v3`. Target checking is **not** here: see
§10 for why it must follow the standard file being loaded.

**Do not store the target kind on `VstAnnotation`.** Walk top-down from the declarations, so
the kind is known at each site by construction. A stored field would be redundant, could
drift from the parser, and cannot distinguish the three things that share `VarDecl` — a
local, a value parameter, and an annotation field.

No new traversal machinery is needed, because the AST is already walked in the three places
annotations live:

| Sites | Hook |
|---|---|
| File, AnnotationType, AnnotationField, Class, Component, Variant, Enum, VariantCase, EnumCase, Field, Method, Constructor, Parameter | iterate `prog.vst.*` and their members — a new `forAll` pass |
| TypeUse | `resolveType` (`Verifier.v3:996`) — see §5 |
| Block | `visitBlock` in the `TypeChecker`, which already visits every block |

Done for each annotation: record `VstAnnotation.target` from the walk, look the name up in
the file's scope, and set `VstAnnotation.binding`. An undeclared name is reported. A name
with more than one visible binding is reported rather than guessed at, since choosing needs
`@target`.

`@repeatable` is enforced here too, since "attached twice at the same position" is one
annotation list and whether a declaration is `@repeatable` is syntactic — neither needs a
value.

Checking the recorded target against the declaration's `@target`, and selecting among
overloads, happen later in `AnnotationChecker` (§10), because both need `@target`
evaluated. An annotation declared with no `@target` is legal anywhere the parser accepts
one.

One wrinkle the walk turned up: a variant case's annotations are attached both to its
`VstCaseMember` and to the `VstClass` lifted to top level, so the class walk skips
synthetics or every `case` annotation is visited twice.

---

## 5. TypeUse: hook `resolveType`, do not traverse

Every `TypeRef` passes through `VstCompoundVerifier.resolveType` (`Verifier.v3:996`), so
hooking it is far cheaper than a traversal that finds every type reference in every
declaration, body, and type-argument list. Two constraints:

- `resolveType` memoizes: `if (tref.binding != null) return tref.binding;` (`:997`). Check
  on the miss path; a `TypeRef` node belongs to exactly one syntactic position, so it is
  checked once.
- The namespace must exist before the first call, which §3 arranges.

**Stage 2 must not let annotations affect `binding`.** An annotated type use becomes a
distinct type only once `@clones_type` exists, and `binding` holds a single resolved `Type`.
Until cloning is designed, a `TypeRef` resolves exactly as it would without the annotation,
and the annotation is recorded and target-checked only. This is the deepest unknown in the
design; see §9.

---

## 6. Pass 3 — argument binding and type checking

The model is `typeCheckEnumCase` (`Verifier.v3:514`): extract parameter types, call
`tc.typeCheckExpr(arg, paramType, what)`, report `ArityMismatch` on a count mismatch.
Annotation arguments are the same shape with three additions.

Binding order, per `doc/annotations-syntax.md` §3.4:

1. Bind keyword arguments to named fields. Unknown name → error; bound twice → error unless
   the field is `@repeatable`.
2. Bind positional arguments left to right to the fields not yet bound.
3. Fill the rest from their initializers; `@required` with no value → error; merely absent →
   the default value of the type.

Annotation fields are `VarDecl` rather than `ParamDecl` precisely so they carry the `init`
that step 3 needs.

Because §2 makes annotations variants, the bound arguments are exactly a variant case's
arguments, and the result is an ordinary variant value. Add to `VstAnnotation`:

```
var boundArgs: Array<Expr>;    // by field index, after binding
var value: Val;                // the variant value, after §7
```

---

## 7. Constant evaluation

The compiler needs values, not expressions: `@target`'s argument decides whether a use is
legal. Implemented in `aeneas/src/vst/AnnotationEval.v3`. There was **no VST-level constant
evaluator** before it — `tryUnboxPositiveInt` (`Verifier.v3:2742`) and match-pattern
extraction (`:1490-1515`) are literals-only, and enum case arguments are not evaluated in
the verifier at all but at SSA-init time.

Building one was tractable because two pieces already existed.

**`VarBinding` carries the resolution.** After type checking, a `VarExpr` for
`TargetKind.Class` has `varbind = EnumConst(member)`; one for `TargetKinds.Container` has
`ComponentField(member)`, whose `member.init` is the expression to evaluate recursively; a
folded constant has `Const(val, vtype)` outright.

**`Eval.doOp` already evaluates operators.** `Eval.doOp(op: Operator, args: Arguments) -> Result`
(`core/Eval.v3:334`) is what both the SSA interpreter and the constant folder use
(`SsaOptimizer.v3:1211`). A `BinOpExpr` holds its resolved operator in `op.op` after type
checking, so `A | B` on an enum set evaluates by calling it. The adapter is small —
`FoldingArguments` (`SsaOptimizer.v3:2347`) is the model; a VST version needs only a `vals`
array and the operator's type arguments.

A new `AnnotationEval` over the post-typecheck AST handles:

| Form | How |
|---|---|
| `Literal` | `lit.val` |
| `VarExpr` / `Const` | the bound value |
| `VarExpr` / `EnumConst` | build the enum value from the case |
| `VarExpr` / `ComponentField` | evaluate `member.init` recursively; cache; detect cycles |
| `BinOpExpr`, `AppExpr` on an `Apply` / `Inst` binding | `Eval.doOp` with the adapter |
| `ArrayExpr`, `TupleExpr` | evaluate elements |
| `AnnotationExpr` | the nested annotation's own value |
| anything else | not a constant — a diagnostic naming the expression |

The domain is bounded by the design note: integers, floats, enums, enum sets, strings,
immutable ADTs and read-only arrays of those, plus other annotations. Rejecting rather than
guessing is the user-visible point of this pass: before it, `@t(Helper.f())` and
`@t(Helper.mutableField)` both type-checked and were silently accepted, though the design
note admits only immutable values.

Two wrinkles found in building it. Enum-set operators are VST *sugar* rather than plain
operators, so `Eval.doOp` does not know them; they reduce to integer bit operations on the
set's representation. And strings cannot go through `Program.getStringRecord` during
verification — its `strRecords` table is not populated that early — so the record is built
directly, and an annotation's string value is not interned with the program's string
constants.

### A narrow form landed first

Target checking cannot bite until `@target`'s argument can be evaluated, so a narrow
evaluator shipped with target checking (`7f0c68e1e`), covering just what the built-in
meta-annotations need: enum constants, enum-set unions, and component-field reads. That
kept the step meaningful instead of leaving its target checks inert. It lives in
`AnnotationChecker` and is deliberately not shared with the general evaluator: the two want
different answers — the narrow one produces a bit set and rejects everything else, while
the general one produces a `Val` for any admissible field type. Merging them would trade a
few duplicated lines for a more awkward interface.

---

## 8. Loading the standard annotations

Per `doc/annotations-syntax.md` §12: a `-lang.annotation-files=<path*>` option, prepended in
`Aeneas.makeProgram` exactly as `RT_FILES` is at `Aeneas.v3:64-71`, gated on
`-lang:annotations`, with the platform wrappers supplying `$LIB/annotations/*.v3`.

- `lib/annotations/TargetKind.v3` parses under any compiler — verified against both
  `bin/current` and `bin/stable`; `Standard.v3` needs the flag. Neither may enter
  `aeneas/DEPS` or an unconditional wrapper glob.
- Diagnose annotations used with no standard file loaded, rather than failing to resolve
  `@target` with a confusing "unknown annotation".

`test/annotations/` needs a second suite for `//@seman` cases, whose `test.bash` passes both
`-lang:annotations` and the annotation-files path via `V3C_OPTS`.

---

## 9. Explicitly deferred to stage 3

- **`@implicit` propagation** — computing a value where no explicit annotation appears,
  flowing inward from containers, including the absence model (`doc/annotations-syntax.md`
  §3.2) and the first-available rule over `@implicit`'s list.
- **`@clones_type` and type cloning** — the `TypeRef.binding` interaction of §5. An annotated
  type use becomes a *distinct* type, which reaches into normalization and reachability; the
  design note expects clones not to be fully determined until those finish.
- **`@retention`** — what Source retention drops, and when.
- **Annotation methods** — invoking user code at compile time (§2).
- **IR propagation.** `IrMember.source` (`Ir.v3:105`, `:123`) already points back at the VST
  declaration, so later phases can read annotations without copying;
  `VstIr.addRepHintFacts` (`VstIr.v3:207`) is the model if copying is wanted.
- **`@this` / `@outer`** as target designators — not annotations, so compiler-side handling
  in the annotation-value sublanguage.
- **Program-level `-@program=` and `-@file=`.**

---

## 10. Order, and progress

**Stage 2 is complete.** It landed in a different order than first planned, corrected twice
along the way; each correction is recorded below because the reasons outlive the schedule.

| Step | Content | Commit |
|---|---|---|
| 2a.1 | Desugar annotation types into open variants (§2) | `93ccc3726` |
| 2a.2 | Build the annotation namespace (§3) | `f77d478d7` |
| 2a.3 | Resolve uses to declarations (§4, §5) | `c72a669c7` |
| 2a.4 | Load `lib/annotations/` (§8) | `4d51f0103` |
| 2b | Argument binding and type checking (§6) | `2a570130d` |
| 2a.5 | `@target`, target checking, overload selection, `@repeatable` (§7, narrow) | `7f0c68e1e` |
| 2c | General constant evaluation (§7 in full) | `3c8018b68` |

### Two ordering corrections

**Loading the standard file must precede target checking.** The first plan had target
checking in 2a and the standard file last. But `@target`'s argument names `TargetKind`,
which lives in `lib/annotations/TargetKind.v3` and exists only once that file is loaded.
Confirmed empirically before building on it: `@target(TargetKind.Class)` compiled clean with
`TargetKind` defined nowhere.

**Argument binding must precede target checking.** Planned as 2b, i.e. after. But deciding
whether a use is legal means *evaluating* `@target`'s argument, and an argument cannot be
evaluated before it is bound and type-checked like any other. Also confirmed first:
`@t(no_such_name_at_all)` compiled clean, because arguments were not resolved at all.

The general shape both corrections share: anything that reads an annotation's **value**
depends on the whole chain — declaration resolved, argument bound, argument type-checked,
value evaluated — and the standard file present for anything naming `TargetKind`.

### Pass placement, as built

In `Verifier.verify()`:

1. `buildFile` for every file.
2. **Namespace** (`AnnotationEnvBuilder`) — must precede any `resolveType` call, since
   annotations on type uses are checked inside it.
3. **Resolution** (`AnnotationResolver`) — binds names, records every use, enforces
   `@repeatable`.
4. The existing `verifyComponent` / `verifyClass` / `verifyEnum` passes, which resolve
   field types.
5. **Argument binding** (`AnnotationBinder`) — needs those field types.
6. The existing `typeCheckVstCompound` passes.
7. **Target checking** (`AnnotationChecker`) — needs step 6, because
   `@target(TargetKinds.Container)` reads a component field whose *initializer* is only
   type-checked there. This was caught by that one spelling failing while
   `TargetKind.Class` and `A | B` both passed.
8. **Evaluation** (`AnnotationEval`).

Steps 5 and 8 both iterate the resolver's list of uses rather than walking the AST again,
which is also what reaches annotations nested inside another's arguments — those are
attached to no site and a site walk misses them.

### Things the implementation added that the plan did not have

- **Overloaded names need distinct synthesized types.** Two declarations of one name were
  synthesizing two variants with the same name, so a *legal* overload failed with
  `TypeRedefined`. Later declarations take a `$n` suffix; the first keeps the plain
  `@name`.
- **`@repeatable` needs no evaluation.** "Attached twice at the same position" is one
  annotation list, and whether a declaration is `@repeatable` is syntactic, so it is
  enforced during resolution rather than with the other target checks.
- **An annotation used as a value has a real type** — its synthesized variant, a subtype of
  the root — so `value: Annotation` accepts any of them by ordinary subtyping. Such uses
  carry a `Value` target with no `TargetKind` counterpart, since `@target` cannot apply to
  something attached to nothing.
- **Strings cannot use `Program.getStringRecord` during verification**; its `strRecords`
  table is not populated that early. `AnnotationEval` builds the record directly, so an
  annotation's string value is not interned with the program's string constants.
- **`-test` mode bypasses `Aeneas.makeProgram`**, so `-lang.annotation-files` had to be
  applied in `Regression.loadProgram` too — without which the option silently did nothing
  under the entire test suite.

### What the seam proved

2a.1 was split as suggested — land the synthesized hierarchy alone before building on it —
and it settled three things by measurement rather than assumption:

- The verifier accepts programmatically built hierarchies. `resolveSuperClass` establishes
  the `extends` relation and `assignVariantTagsIfRoot` runs; a root without `case _` would
  have failed at `Verifier.v3:655`.
- Unreachable synthesized types cost nothing. The same program compiled with and without
  three annotation declarations differs by exactly one byte — the source filename in the
  source tables.
- **Annotations do not require `-lang:open-types`.** Both gates (`Parser.v3:322` and `:555`)
  are purely syntactic and the verifier's own checks are ungated, so desugaring after
  parsing bypasses them. This retires the dependency risk recorded in §2.

### Naming, as built

The root is `@Annotation` and each annotation type is `@` plus its name. Every synthesized
name carries a `@`, which cannot appear in an identifier, so none can be declared or
referenced by a user. Naming the root plain `Annotation` was tried first and rejected: it
occupied an attractive identifier program-wide, and a user's own `class Annotation` then
collided with a diagnostic pointing at the synthetic `<annotations>` file they never wrote.

So that `lib/annotations/Standard.v3` can still say what it means, a bare `Annotation` in
an **annotation field type** is rewritten to `@Annotation` during desugaring, nested
positions included. Elsewhere the name means nothing special and a user may define their
own — in which case an annotation field written `value: Annotation` still means the root,
not their class.
