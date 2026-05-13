# Claude Guide to Virgil

A practical reference for working with Virgil code, tests, and the compiler.
Companion to `doc/grammar-claude.md` (full grammar) and `doc/tutorial/` (language tutorial).

---

## Declaration Kinds

| Keyword | What it is | Instance? | Mutable? |
|---------|-----------|-----------|---------|
| `class` | heap-allocated object | many (`.new()`) | yes (`var` fields) |
| `component` | singleton module | one per program | yes (`var` fields) |
| `type` | algebraic data type (ADT/variant) | value-typed | no (immutable cases) |
| `enum` | integer-backed enumeration | tag + name | no |

Top-level `var x: T;` and `def x: T = ...;` are global mutable / immutable variables.

---

## Class Members

```virgil
class C(x: int, y: int) { }          // constructor params → immutable fields (def-like)
class C { var x: int; }              // mutable field, zero-initialized
class C { def x: int = 3; }          // immutable field with initializer
class C { var x: int; new(v: int) { x = v; } }  // constructor body sets var field
```

- **Constructor params** `class C(x: T)` create **immutable** fields — loads from them
  can always be forwarded to the stored construction value.
- **`var` fields** are mutable; the optimizer may forward loads when it can prove no
  intervening store.
- **`def` fields** (inside the class body) are written once at construction and then
  immutable — also eligible for load forwarding.

Inheritance:
```virgil
class Sub extends Base(args) { ... }   // calls super constructor with args
class Sub extends Base { new(x: int) : super(x) { } }  // explicit super call
```

**Method chaining with `-> this`:** a method returning `this` returns its receiver, enabling chains:
```virgil
class Builder {
    def add(x: int) -> this { ... }
}
builder.add(1).add(2).add(3);
```
`StringBuilder` uses this throughout: `buf.puts("x").putc('[').putd(n).putc(']')`.

---

## ADT / Variant Cases

```virgil
type Color { case Red; case Green; case Blue; }              // no-field cases
type Option { case Some(value: int); case None; }            // mixed
type Tree { case Leaf(v: int); case Node(l: Tree, r: Tree); } // recursive
```

Construction:
```virgil
var x = Option.Some(42);   // case with fields: call like a function
var y = Option.None;       // no-field case: no parens needed
```

Field access — two styles:
```virgil
// Style 1: variable is already the specific case type
var s: Option.Some = Option.Some(5);
var v = s.value;

// Style 2: cast from parent type after a type query
var o: Option = getOption();
if (Option.Some.?(o)) {
    var v = Option.Some.!(o).value;
}

// Style 3: match with destructure
match (o) {
    Option.Some(v) => return v;
    Option.None    => return 0;
}
```

**Simple single-case ADTs** (no cases declared) are struct-like:
```virgil
type Point(x: int, y: int) { }   // construct: Point(3, 4); access: p.x, p.y
```
Fields of simple ADTs are always immutable; all loads forward to construction values.

ADT built-in fields (available on every case):
- `.tag` — integer case index (0-based declaration order)
- `.name` — string name of the case

```virgil
type Color { case Red; case Green; case Blue; }
Color.Red.tag    // => 0
Color.Green.tag  // => 1
Color.Red.name   // => "Red"
```

---

## Match Statements

```virgil
match (expr) {
    Option.Some(v) => singleExpr;            // single-expression arm
    Option.None    => { stmt1; stmt2; }      // block arm for multiple statements
    _              => ;                      // catch-all, no-op arm
}
```

- Match on a `type` (ADT) is **exhaustive**: the compiler errors if any case is unhandled
  unless a `_` wildcard is present.
- `_ => ;` is a valid catch-all with an empty (no-op) body.
- OR patterns (`A | B => expr`) grouping multiple cases are **not** supported;
  list each case separately or use `_`.
- Short arms use `=>` (no braces); multi-statement arms use `=> { ... }`.

---

## Visibility

- `private` — accessible only within the same **file**.
- No other access modifiers (`public`/`protected` do not exist); members without
  `private` are accessible from anywhere in the program.

---

## Type Casts and Views

```virgil
T.!(expr)      // downcast to T; throws TypeCheckException at runtime if wrong
T.?(expr)      // type query; returns bool
T.view(expr)   // reinterpret bits (no runtime check; integer, float, Pointer, and bool types)
void(expr)     // discard result of evaluating expr
```

Common uses:
```virgil
byte.!(x)         // int → byte: truncate to lower 8 bits (throws if out of range)
int.!(b)          // byte → int: zero-extend
byte.view(x)      // reinterpret lower 8 bits of int as byte (no range check)
u32.view(i)       // reinterpret int bits as u32
i8.view(x)        // reinterpret lower 8 bits as signed i8
```

`T.!` and `T.?` can also be used as first-class functions:
```virgil
var f: Option -> Option.Some = Option.Some.!;
var g: Option -> bool = Option.Some.?;
```

---

## Test File Format

Each test is a single `.v3` file. The **first line** is a directive comment:

### `//@ execute` — compile and run

```
//@execute = value                    // no-arg main, check return value
//@execute input=value                // single int input
//@execute input=!ExceptionName       // expect runtime exception
//@execute i1=r1; i2=r2; i3=r3       // multiple runs, semicolon-separated
//@execute (a, b)=result              // two-arg main (tuple input)
//@execute (a, b)=!ExceptionName      // two-arg, expect exception
```

Value syntax: decimal integers (including negative), `true`, `false`, char literals `'x'`.

Exception names: `NullCheckException`, `BoundsCheckException`, `LengthCheckException`,
`TypeCheckException`, `DivideByZeroException`, `StackOverflowException`.

Optional second line:
```
//@heap-size=N    // set interpreter heap size in bytes (for GC tests)
```

### `//@ seman` / `//@ parse` — semantic / parse-only tests

```
//@seman           // expect successful semantic analysis
//@seman=ErrName   // expect a semantic error named ErrName
//@parse           // expect successful parse
//@parse=ErrName   // expect a parse error
```

### Multi-file tests (seman only)

```virgil
//@seman
// ... content of first file ...
//@file             // rest becomes a second source file named "test"
//@file=foo.v3      // rest becomes a file named foo.v3
// ... content of second file ...
```

### Notes

- `//@ optimize` comments seen in some tests are **not directives** — they are
  explanatory comments indicating which optimization the test exercises.
- Run a single test: `v3c-dev -test path/to/test.v3`
- Tests run through the interpreter by default; `execute_tests` also compiles to
  all configured native targets.

---

## Optimizer Passes (SsaOptimizer)

Source: `aeneas/src/ssa/SsaOptimizer.v3`

| Pass | What it does |
|------|-------------|
| Load elimination | Forwards stored values to subsequent loads; eliminates redundant loads after `new` |
| Null check elimination | Removes null checks that are provably redundant |
| Constant folding | Evaluates arithmetic/logic on known-constant values at compile time |
| Dead code elimination | Removes unreachable blocks and unused computations |
| Inlining | Inlines small callees into callers |
| Devirtualization | Resolves virtual dispatch to a direct call when concrete type is known |
| Allocation elimination | Removes object allocations whose results are never observed |

The optimizer is invoked per-method on the SSA graph before normalization.
Load elimination is controlled by `Compiler.LoadOptimize` (on by default).

### Load/store test patterns

For testing load/store optimizations, put class-based tests in `test/core/` and
ADT-based tests in `test/variants/`. Naming convention: `opt_<topic>NN.v3`.

Common scenarios worth testing:
- **Init forwarding**: `A.new(expr).field` → `expr` (no actual load needed)
- **Redundant load**: same field read twice without intervening store → one load
- **Store forwarding**: store to field then immediately load → use stored value
- **Dead store**: write to field that is never read → store can be removed
- **Alias disambiguation**: store to `p.f` should not kill forwarded load from `q.f`
  when `p` and `q` are provably different objects

---

## Integer Types

| Type      | Width  | Signed | Notes                  |
|-----------|--------|--------|------------------------|
| `i8`      | 8-bit  | yes    |                        |
| `u8`/`byte`| 8-bit | no     | `byte` is an alias     |
| `i16`     | 16-bit | yes    |                        |
| `u16`     | 16-bit | no     |                        |
| `i32`/`int`| 32-bit| yes    | `int` is the default   |
| `u32`     | 32-bit | no     |                        |
| `i64`/`long`| 64-bit| yes   | `long` is an alias     |
| `u64`     | 64-bit | no     |                        |

`int` = `i32`, `long` = `i64`. Integer literals default to `int`; use `u` suffix for
unsigned, `l`/`L` for `long`. Generic methods (e.g. `StringBuilder.putd<T>`) dispatch
on these concrete types, so `int` matches the `i32` arm.

---

## Common Gotchas

- `_` is **not** a valid identifier start (it's a keyword token for wildcards/partial app).
- `if(a, b, c)` is an **expression**; `if (cond) stmt` is a **statement** — different syntax.
- Integer literals are `int` by default; use `u` suffix for unsigned, `l`/`L` for `long`.
  - `0x100000000` is out of range for `int`; write `var x: long = 0x100000000` instead.
- `long.!(expr)` is a cast (safe for positive ints); not needed for literal constants.
- `class C(x: T)` constructor params are immutable (`def`-like), even without `var`.
  Adding `var` to a constructor param (`class C(var x: T)`) makes it mutable.
- No `//@ optimize` directive exists in the test framework — those comments are notes only.
- The `type` keyword declares ADTs, not type aliases; there is no `typealias` in Virgil.
