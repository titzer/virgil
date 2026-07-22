# Tooling wishlist

Friction encountered while working on `iN.pack`/`iN.unpack`: writing ~70 tests,
bisecting six bugs, and editing the compiler. Ordered by how much time each cost.
Where I'm guessing at implementation difficulty, I say so.

## 1. Constant folding silently hides runtime bugs

This was by far the biggest one. Four of the six bugs I found were invisible to a
test with constant inputs, because `Eval` folds the whole computation at compile
time and never exercises the generated code:

| bug | constant input | runtime input |
|-----|----------------|---------------|
| `unpack<E>` int->enum subsume | correct | `InternalError` |
| `unpack<E.set>` in a wide container | correct | silently `{}` |
| `unpack` of a generic data type | correct | compiler NCE |
| wasm narrowing `unpack` in a loop | correct | `UNREACHABLE` trap |

`test/variants/tuple_unpack*.v3` -- 271 tests -- are all constant-input
round-trips, so none of them caught any of this.

**Suggested fixes**, cheapest first:

- A test annotation, e.g. `//@execute-nofold 0=1`, that wraps each `main`
  argument in an opaque identity the optimizer cannot see through. I emulated
  this by hand in ~40 tests (`def f(v: u8) -> ... { ... }` called with
  `u8.view(a)`), which is boilerplate that belongs in the harness.
- Better: a `-fold=false` / `-opt-fold=false` compiler flag, and a test-suite
  mode that runs the *existing* corpus twice, once with folding disabled. That
  would have caught all four bugs above with no new tests written.
- A `--dump-opcodes` or coverage-style report of which opcodes a test actually
  reached post-optimization would make "did this test exercise the path I think
  it did?" answerable. Right now the honest answer is usually "no idea".

## 2. Test output is hostile to reading

Every single test invocation this session went through:

```bash
./test.bash foo.v3 2>&1 | tr '|' '\n' | sed 's/\x1b\[[0-9;]*m//g' | grep -E "fail:" 
```

The progress format packs everything onto one line separated by `|`, with ANSI
colour codes interleaved, so neither `grep` nor eyeballing works directly.

- Add `--plain` (no colour, newline-separated) and `--quiet` (failures only).
- Honour `NO_COLOR` / non-TTY stdout automatically -- that alone fixes most of it.
- Have the suite print a final failure list, once, at the end. Today I have to
  reconstruct it from a 500KB stream.

## 3. `<null>` failure messages

```
##-fail: (0)=<null>, expected: 1
```

This is what you get when a test crashes or returns something unrenderable. It
tells you nothing. I lost real time on `packlayout24` and the enum-set bisect
before realising I had to re-run under `-run` to see the actual exception. The
harness clearly has the error in hand -- print it:

```
##-fail: (0)=!InternalError: subsume should never fail
           at main() [foo.v3 @ 12:34]
```

## 4. No quick expression evaluator

To learn "what does `u16.pack<(u4,u4,u4,u4)>((0xA,0xB,0xC,0xD))` actually
produce?" I had to write a file with a `main`, a `System.puti`, and a
`System.puts("\n")`, then run it. I did this dozens of times.

```bash
v3i -e 'u16.pack<(u4,u4,u4,u4)>((0xA,0xB,0xC,0xD))'    # => 43981
v3i -e -x 'u16.pack<...>'                              # => 0xABCD
```

Accepting a `-e` expression (with an implicit `main` wrapper, and printing the
result with its type) would collapse a 4-tool loop into one command. Being able
to pass a file of declarations alongside (`v3i -f types.v3 -e '...'`) would cover
most of the rest.

## 5. Discovering expected error text requires two runs

The workflow for every one of the ~40 seman tests I wrote was:

1. write the test with a bare `//@seman`
2. run it, read the reported `TypeError @ 3:17`
3. `sed -i` the annotation back into line 1
4. re-run to confirm

That is a snapshot test with no blessing mechanism. Add one:

```bash
v3c -test -update foo.v3      # rewrite the annotation to match actual output
v3c -test -update test/core/seman/*.v3
```

With an obvious caveat that it must be reviewed, this turns a 4-step loop into
one command. It would also make bulk changes tractable -- when I changed a
diagnostic message this session, re-blessing was manual.

## 6. `-run` argument passing

```bash
bin/dev/v3c-dev -run foo.v3 1
```

does not feed `1` to `main(a: int)` -- `a` is silently 0. (`main(a: Array<string>)`
does receive them, and `v3i` behaves the same way, so this is about the typed-main
form, not about `-run` specifically.) I spent a while convinced I had found a
miscompile -- a field arriving as 0 before packing -- when in fact the argument
never arrived. Either coerce arguments to a typed `main` the way the `-test`
harness does, or reject extra arguments when `main` cannot accept them. Silently
substituting 0 is the worst option, and the divergence from `-test` -- which
*does* pass typed arguments -- is what made it costly.

## 7. Shorten the edit-compiler -> run-suite loop

`v3c-dev` interpreting current source is genuinely great for one-off checks. But
`test/all.bash` runs against `bin/current`, so validating a compiler change needs
`make bootstrap` (~1-2 min) first. I did that eight times today.

- `AENEAS_TEST=dev` (or `TEST_COMPILER=v3c-dev`) to run a suite directly against
  interpreted current source. Much slower per test, but for "did my 5-line
  normalizer change break `test/layout`?" it is the right trade.
- A `--changed-only` mode that runs tests touching files changed since a given
  ref would help even more, though I appreciate that requires a mapping that
  doesn't exist today.

## 8. Flaky SIGKILL on macOS

Four separate runs, four different tests (`abstract00`, `alt00`, `add_long08`,
`array_load_elim00`), each `unexpected signal 9`, each passing in isolation. It
looks like macOS killing a freshly written binary -- a code-signing or page-cache
race rather than anything in the compiler.

Cost: every suite run, I had to re-run the failure to decide whether it was mine.
Suggest the harness retry once on signal 9 and report `flaky` rather than `fail`,
or `sync`/re-`exec` after writing the binary. Even just a distinct exit status
for "only flaky failures" would let me trust a green run.

## 9. Bisecting needs throwaway programs

Isolating each bug meant writing 5-10 near-identical one-off files. A way to feed
a program on stdin (`v3c -test -` / `v3i -`) would let me generate and test
variants in a single shell loop without touching the filesystem. I ended up
building exactly that with heredocs into a scratch file, badly, many times.

## 10. Smaller things

- `test/all.bash` runs all eight targets by default; `TEST_TARGETS` is the
  documented escape hatch but is easy to miss. A `--fast` alias for
  `TEST_TARGETS="v3i"` would be a good default for iteration.
- `bin/v3c` runs the stale bootstrap JAR while `bin/dev/v3c-dev` interprets
  current source, and `bin/v3c-x86-64-darwin` uses stable unless `V3C=` is set.
  This is documented in `CLAUDE.md` and I still had to think about it each time.
  A single `v3c --which` that prints the binary actually being used would remove
  the doubt. (Being able to say "compare stable vs current" easily *was* useful
  for proving a bug pre-existed -- a first-class `--compare-stable` would make
  that a one-liner.)
- Test file naming has no convention for "this is a known-failing repro". I used
  `test/fail/`, which is right, but `test/fail` is not in `test/all.bash`, so
  nothing ever checks that those tests still fail *for the stated reason*. A
  suite that asserts "these fail" would catch a bug being silently fixed -- which
  happened twice today.
