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
//@heap-size=<bytes>            // only when the test needs a larger heap

var crc: int;
def acci(x: int) { ... }        // the accumulator
def accl / accb / accs / accf   // typed feeders, as needed

def sectionOne() { ... }        // one section per feature group
...

def run(a: int) {
	crc = a * 0x9E3779B9;   // seed distinguishes sections
	if (a == 0 || a == 1) sectionOne();
	...
}
def main(a: int) -> int {
	run(a);
	return crc;
}
```

**Why a CRC instead of `if (x != K) return ID`.** A comparison against a
constant can be folded away and deleted, so the check would silently stop
testing anything in optimized builds. Folding every observed value into a
running hash keeps each value live on the path to the return value.

**Input 0 runs every section** in a single method body. That is deliberate: it
produces a much larger SSA graph than any individual section and puts real
pressure on register allocation and spilling. Inputs 1..N select one section
each, so a failure narrows to a section immediately.

**Sections must not depend on each other.** The harness may run several inputs
in one process (`v3i -test`) or one process per input (compiled targets). Any
section that writes a global must reset that global on entry, or the two
execution models will disagree.

## Adding a test

1. Write the sections. Keep values flowing from arrays/globals rather than
   literals, so the optimizer cannot fold the whole section away.
2. Verify the semantics you are encoding *before* recording any CRC — by hand,
   or with a scratch program that asserts hand-derived expected values. The CRC
   records whatever the compiler did; it does not check that this was correct.
3. Record the CRCs only after `v3i`, `v3i -ra -ma=false`, `v3i -ra -ma=true` and
   at least one compiled backend all agree. A disagreement is a compiler bug to
   report, never something to bless into the directive.

If a construct turns out not to be portable across backends, leave a comment
saying so at the site rather than silently deleting the check.

## Known non-portable constructs (deliberately not tested here)

- **Variant equality with a NaN float payload.** Constant-folds to `true`, but
  evaluates to `false` at runtime on compiled backends. Affects boxed and
  unboxed variants alike.
- **Equality of a function value against an operator reference** (`g == int.+`).
  The interpreter and the compiled backends disagree in some contexts.
  Equality of ordinary function values is portable and is tested.
