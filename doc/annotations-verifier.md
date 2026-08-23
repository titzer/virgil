# Virgil Annotations — Verifier Plan

Status: **plan**. Nothing here is implemented.

Scope: stage 2 — give the parsed annotations meaning. Desugar annotation declarations into
real types, resolve each `@name` to its declaration, check it against the target it is
attached to, bind and type-check its arguments, and evaluate them to compile-time values.
Everything downstream — `@implicit` propagation, `@clones_type` and type cloning, retention,
IR propagation — is stage 3 and is listed in §9.

Stage 1 (`doc/annotations-parser.md`, commit `6fa363f16`) parses and stores. It resolves
nothing, and `AnnotationExpr` / `AnnotatedExpr` currently report
`"annotations are parsed but not yet verified"` if they reach the type checker. Stage 2
replaces that with real behaviour.

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

`VstAnnotation.decl` is the mutable slot stage 2 fills in.

---

## 2. Annotation types are desugared into open variants

**Decision: each `@type foo` becomes a synthesized variant `A@foo`, a subtype of a
synthesized open root `A@`.** No type-system change is needed, because variants already
answer every representation question, and unreachable synthesized variants cost nothing in
a whole-program compiler.

This is what `doc/ideas/Annotations.txt` already sketches, in the language's own syntax:

```
type A@ { }                                              // root of the hierarchy
type AM@ extends A@ { }                                  // meta-annotation root
type AM@target(value: TargetKind.set) extends AM@ { }
type A@deprecated(why: string, date: Date) { }
```

`extends` on a `type` is the open-variant feature, so the note is describing exactly this.

The machinery exists. `VariantDesugaring` (`Vst.v3:272`) already synthesizes `VstClass`es
with `kind = Kind.VARIANT`, `isSynthetic = true`, and a `fullName` distinct from the
declared token — `synthesizeTopLevelClass` (`:286`) and `synthesizeVariantCaseMember`
(`:299`). Annotation desugaring is the same shape.

What this buys, all for free: annotation instances are ordinary variant values, so `Val`,
type checking, subtyping, field defaults, and `Eval.doOp` need no new code; and
`@type implicit(value: Annotation)` is an ordinary field declaration whose type resolves to
the root.

### Naming keeps them out of the ordinary namespace

Synthesized types are named `A@foo`. `@` cannot appear in an identifier, so a user can
neither declare nor reference one, and the annotation namespace stays separate from the
type namespace as `doc/annotations-syntax.md` §2 requires. The name is only a string key in
the type environment, so nothing needs to parse it. It also reads clearly in diagnostics.

`Annotation`, written by a user in an annotation field's type, resolves to the root `A@`.

### Where the root comes from

The root must exist exactly once program-wide, but `@type` declarations are spread across
files, so it cannot be synthesized per file. Synthesize it **before `buildFile`**, into a
synthetic `VstFile` prepended to `prog.vst.files`, and have each `@type`'s desugaring
reference it by name. Declaring it in `lib/annotations/Standard.v3` instead is not an
option, since `A@` is unwriteable.

The root needs a `case _`, because open-variant subtypes require one.

### Risks worth naming

- **Annotations now depend on `-lang:open-types`** as well as `-lang:annotations`. Either
  gate on both, or have the annotations flag imply open types.
- The open-variant machinery has not previously been driven by **programmatically
  synthesized** hierarchies — only by parsed ones. DFS tag assignment, `variantTagHi`
  ranges, and `case _` handling should be exercised early with a small hand-built case
  rather than discovered late.
- Desugaring must not make the synthesized types **reachable**. Nothing constructs them at
  runtime under Source retention, so reachability analysis should drop them; verify that it
  does rather than assuming.

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
	def map: HashMap<string, List<AnnotationBinding>>;   // Strings.newMap()
	def lookup(name: string, target: TargetKind, file: VstFile) -> AnnotationBinding;
}
type AnnotationBinding {
	case Decl(d: VstAnnotationDecl);
	case Alias(a: VstAnnotationAlias);
}
```

Checks here:

- Declarations sharing a name must have **disjoint** target sets; report at the second
  declaration, not at a use.
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

## 4. Pass 2 — resolution and target checking

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

For each annotation: look up the name for that target kind, set `VstAnnotation.decl`,
report a use no overload covers with a message naming the kind sought, then enforce
`@repeatable`.

An annotation declared with no `@target` is legal anywhere in `TargetKinds.Supported`; one
whose `@target` lies wholly outside `Supported` can never be used and should be reported at
its declaration.

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
legal. **There is no VST-level constant evaluator today** — `tryUnboxPositiveInt`
(`Verifier.v3:2742`) and match-pattern extraction (`:1490-1515`) are literals-only, and enum
case arguments are not evaluated in the verifier at all but at SSA-init time.

Building one is tractable because two pieces already exist.

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
immutable ADTs and read-only arrays of those, plus other annotations. Reject rather than
guess.

### A narrow form lands first

Target checking cannot bite until `@target`'s argument can be evaluated, so a **narrow
evaluator ships in step 2a** (§10) covering just what the built-in meta-annotations need:
enum constants, enum-set unions, and component-field reads. That is three rows of the table
above, and it keeps every step of the staging meaningful instead of leaving 2a's target
checks inert. The general evaluator then extends it rather than replacing it.

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

## 10. Suggested order

Each step independently testable:

1. **2a — desugaring, namespace, resolution, target checking.** §2, §3, §4, §5, plus the
   narrow evaluator of §7. Arguments limited to arity. Testable with `//@seman` cases for
   unknown names, wrong targets, duplicate non-repeatable annotations, and overlapping
   overloads — and target checks actually bite, because the narrow evaluator can read
   `@target`.
2. **2b — argument binding.** §6: keyword, positional, defaults, `@required`, type-checked.
3. **2c — general constant evaluation.** §7 in full, extending the narrow form.
4. **2d — the standard file.** §8, end to end.

Step 2a is the largest, because the desugaring in §2 has to be right before anything else
can be built on it. If it needs splitting, the natural seam is to land the synthesized root
and one hand-written `@type` first — proving the open-variant machinery tolerates
programmatic construction — before wiring up the namespace and resolution.
