TODO list for adding new feature: extended enum

Description:  Extended enums introduce open subtypes to enums, rather
analogous to the open types extension to variants.  The feature can be added
in these stages:

1. Allow an _ "case" in enum types.
   Example: enum E1 { A, B, _ }
   Example: enum E2 { _ }
   Todos:
   - Extend the syntax
   - Extend the semantic checking
2. Allow subtype enums for enums that have an _ case
   Example: enum E1.More { C, D }
   Example: enum E1.EvenMore { E, F, _ }
   Example: enum E1.EvenMore.Deeper { G }
   We should be able to deal with default values for enum types similarly to default values for variants.
   Subtype enums must include the fields of their supertype.
   The .name for E1.More.C should be "More.C" and for E1.EvenMore.Deeper.G should be "EvenMore.Deeper.C" (subtype enum case names should include their subtype's name)
   Add .shortName which gives only the last component of the name: E1.More.C.shortName should be "C", etc.
   Todos:
   - Extend the syntax
   - Extend the semantic checking
   - Add implmentation for .shortName
3. Allow methods for enum types. [DONE]
   Example: enum E1 { A, B, _; def m1() => 0; }
     Note that the enum's methods are separated from its cases by a ';'.
   Subtype enums can override inherited methods.
   Per-case method overrides (case { def ... }) were re-introduced in Strategy B
   via synthetic per-case RaClasses (branch open_enums3b) — only cases with
   their own `{ def ... }` body get a synthetic class, the rest share the
   parent. Strategy A (open_enums3a) keeps the type/subtype-only model.
   Todos:
   - [x] Extend the syntax (sub-stage 3.1: enum-level methods after ';')
   - [x] Extend the semantic checking (sub-stage 3.1: basic method resolution)
   - [x] Subtype method inheritance with overrides (sub-stage 3.3)
   - [x] Per-case method overrides (Strategy B, branch open_enums3b)
   - [x] Method closures (sub-stage 3.4: `var f = e.m; f()`)
   - [x] Wasm/wasm-gc backend support (indirect adapters, sig handling, no Oop for enums)
   - [x] JVM backend support (closure adapter, M_ABSTRACT guard in JvmV3EnumGen)
   - Implementation note: dispatch uses tag-indexed array of function values (no boxed enum
     objects needed). The tag type is prepended to the method's normalized function type.
     CallFunctionDirect (no Oop prepend) is used instead of CallFunction for enum dispatch.
   - Closure note: VariantGetMethod/VariantGetVirtual/VariantGetSelector ops are shared
     between variants and enums. Enum values are integers (not Records), so the interpreter,
     optimizer constant-fold, and optimizer CallClosure handler all need EnumType guards.
     The optimizer must also set O_NO_NULL_CHECK for enum receivers (tag 0 is valid).
   - Strategy B optimizations: per-case RaClass elision (only cases with overrides
     get a synthetic class), queue-based per-case liveness, and the optional
     `-compact-mtable=N` (off by default) for compacting redundant mtable rows.
4. Allow subtypes to redeclare supertype fields [DONE]
   Given supertype enum E3(x: int) { A(1), B(17), _ }, example subtype
   declarations:
     enum E3.S1(x: int) { C(10) } // if field declarations are repeated, they must use the same names and types, in the same order, as the supertype
     enum E3.S2(super) { D(15) } // the keyword 'super' means "repeat the supertype fields here":
     enum E3.S3 { H(23) }  // restating supertype fields is not required
   Todos:
   - [x] extend syntax
   - [x] extend semantics
5. Allow subtypes to *add* fields [DONE]
   Given supertype enum E4(b: bool, i: int) { A(true, 0), B(false, 1), _ },
   example subtype declarations that add new fields:
     enum E4.S1(b: bool, i: int, f: float) { F(false, 2, 1.0f) }  // restate supertype field and add new ones
     enum E4.S2(super, f: float) { G(true, 3, 4.5f) } // use 'super' to indicate presence of supertype fields
     enum E4.S3(f: float) { H(true, 2, 5.1f) } // error: must restate supertype fields or use super when adding fields
   Added fields can be implemented using a global array just as original enum fields do
   Multi-level field inheritance works: 'super' means "parent's effective params"
   (root params + all intermediate ancestors' extras). Grandchild E.S.T inherits
   both root E's fields and intermediate E.S's extra fields.
   Todos:
   - [x] extend syntax
   - [x] extend semantics
   - [x] extend implementation
   - [x] multi-level field inheritance
