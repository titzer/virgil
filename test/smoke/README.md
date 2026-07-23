# test/smoke

Medium-sized integration tests. Where `test/core`, `test/float`, `test/variants`
and friends isolate one feature per file so a failure names the bug, these files
combine many features at once so that *combinations* get exercised: the same
values flow through tuples, arrays, ranges, globals, component fields, class
fields and variant cases, under enough allocation to make the GC and the runtime
participate.

They are not a replacement for the micro tests. They are the layer that catches
what only shows up when features are used together.

## File conventions

Each file is standalone (the harness compiles every test separately with
`-multiple`, so there is no shared helper file) and follows this shape:

```
//@execute 0=<crc>; 1=<crc>; ... N=<crc>
//@heap-size=<bytes>

var crc: int;
var failed: int;

def mix(h: int, x: int) -> int { ... }   // pure; returns the new hash
def mixl / mixb / mixs / mixf / mixd     // typed feeders, as needed
def acci(x: int) { crc = mix(crc, x); }
def fail_assert(id: int) { if (failed == 0) failed = id; }

def sectionOne() { ... }                 // one section per feature group

def run(a: int) {
	crc = a;                         // seed is just the section number
	failed = 0;
	if (a == 0 || a == 1) sectionOne();
	...
}
def main(a: int) -> int {
	run(a);
	if (failed != 0) return failed;
	return crc;
}
```

### Two complementary checking styles

**The CRC** covers the bulk, data-driven work. A comparison against a constant
can be folded away and deleted, so it would silently stop testing anything;
mixing every observed value into a hash that `main` returns keeps the values
live. Hot loops accumulate into a **local** `h` and call `acci` once per group —
one global update per loop, not per value. Keep `acci` call sites to a few dozen
per file, not thousands.

**Assertions** (`if (expr != K) fail_assert(id);`) are the opposite: their
operands are deliberately compile-time constants, so the optimizer is expected to
fold them away entirely. They encode what the answer *should* be, which the CRC
cannot: a CRC records whatever the compiler did. A folding bug shows up as
`main` returning the assertion id instead of a hash. Ids are `section*100 + n`.

### Rules

**Input 0 runs every section** in a single method body — a much larger SSA graph
than any individual section, which pressures register allocation and spilling.
Inputs 1..N select one section each, so a failure narrows immediately.

**Sections must not depend on each other.** The harness may run several inputs in
one process (`v3i -test`) or one process per input (compiled targets). Any
section that writes a global must reset that global on entry, or the two
execution models will disagree.

**`//@heap-size` is not decorative.** It is consumed by the wasm and wasm-gc
backends (`WasmTarget.v3`, `WasmGcTarget.v3`) to size the module's linear-memory
heap; the default is only 1024 bytes, so any allocating test needs a realistic
value. The v3i interpreter ignores it.

Note that `-target=wasm-test` links **no garbage collector**: the allocator is a
bare bump pointer that traps `unreachable` once it passes the end of the heap.
Allocation is therefore monotonic, and the wrapper runs every input in a single
instance, so the heap must be large enough to hold the allocation of an *entire
run* — not merely the peak live set. A test that fits comfortably on v3i, wasm-gc
and the native targets (all of which do collect) can still exhaust the heap here,
and the symptom is a `RuntimeError: unreachable` trap rather than a wrong value.
The same directive is reused by `test/gc`, which does run a real collector, so
raising it trades a little GC stress there for a green wasm build.

## Adding a test

1. Write the sections. Keep values flowing from arrays/globals rather than
   literals, so the optimizer cannot fold a whole section away.
2. Add assertions for the facts you actually know, derived by hand. These are
   the part that encodes intended semantics.
3. Record the CRCs only after `v3i`, `v3i -ra -ma=false`, `v3i -ra -ma=true` and
   a compiled backend built from **current source** all agree. Do not cross-check
   against `bin/stable` — it lags (e.g. `test/funexpr/op_eq04b.v3` fails there
   but passes on current), and a stale backend produces false divergences.
4. A genuine disagreement is a compiler bug to report, never something to bless
   into the directive.

If a construct turns out not to be portable across backends, leave a comment
saying so at the site rather than silently deleting the check.

## Currently disabled tests

These carry a `.v3.fail` extension, so the `*.v3` glob in `test.bash` skips them
and they are also left out of `test/gc/smoke.gc`:

- `gc01`, `gc03`, `work01`, `work03`, `work04`

They were committed with a placeholder `//@execute 0=0` and never blessed. Their
values do agree across v3i, wasm-gc and a GC-free wasm-linear run
(`gc01=-1315312563`, `gc03=1729852229`, `work01=-1465536795`,
`work03=1541062172`, `work04=-648465453`), but that is only three execution
models that share the property of *not* using a shadow stack for GC roots; the
native x86 targets that CI actually runs were not verified. Since these are
allocation-churn tests aimed squarely at GC root tracking, blessing them from
the interpreter alone risks encoding a wrong answer. Re-enabling them means
following the blessing procedure above against a native target, and treating any
disagreement as a compiler bug to report rather than a value to record.

## Known non-portable constructs (deliberately avoided here)

Each is excluded at the use site with a comment, and distilled into a `*.v3.fail`
test in the directory that owns the feature. `.v3.fail` keeps the test next to
its feature without running it.

- **Aggregate equality over a float payload.** Compared bitwise by the constant
  folder and the interpreter, but lowered to per-field IEEE `==` during
  normalization/codegen, so folded and runtime answers differ. NaN and signed
  zero show the two opposite symptoms. See `test/variants/eq_nan{00,01,02}.v3.fail`
  and `test/core/tuple_eq_zero00.v3.fail`.
- **Reading a `double #big-endian` layout field.** Not byte-swapped on compiled
  backends; the write side is correct. See `test/layout/read_double_be00.v3.fail`.

Other bugs these tests surfaced, which do not constrain how tests are written:
`test/core/match_span00.v3.fail` (compiler crash when a `match` spans more than
`int.max`), `test/core/neg_zero_lit00.v3.fail` (`-0` lexes as a double with the
wrong value), `test/range/query00.v3.fail` (`Range<T>.?` contradicts `Range<T>.!`).

## Notes on Virgil that these tests ran into

- Closures capture locals **by value**; a captured local cannot be assigned, so
  mutable closure state has to live in a heap object. A captured *array
  reference* does see later element writes.
- `var t = Tree.Leaf;` infers the case type, not the parent; write
  `var t: Tree = Tree.Leaf;` before reassigning. Cross-case comparisons and
  queries likewise need a parent-typed operand.
- Variant cases have a built-in `.name`, so a case field named `name` is a
  redefinition error.
- Variant equality compares string/array payloads **by reference**, so two
  structurally identical values built with separate string literals are unequal.
- Shift operator references are `(int, byte) -> int`, not `(int, int) -> int`.
- Forming a delegate on a null receiver traps at bind time, not call time.

## Per-test compiler flags

A test may carry extra compiler flags in a sibling `<test>.v3.flags` file, which
lets this suite cover language features that are still behind a flag. For
example `descriptor01.v3.flags` contains `-lang:descriptors`.

`test.bash` groups tests by their exact flag string and runs `execute_tests`
once per distinct group, so a flagged test still gets the full multi-target
treatment (all three v3i configs, jvm, wasm, native) rather than v3i only.
Unflagged tests all run together as one group.

When blessing a flagged test, the same flags must be passed to every
configuration, or the CRCs will not agree.

Note that `test/gc/smoke.gc` indexes only the **unflagged** tests: the gc suite
compiles everything it is given in a single command with one shared flag set, so
a flagged test cannot be added there without giving that suite the same grouping
treatment.
