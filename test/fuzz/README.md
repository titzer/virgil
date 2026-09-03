# Virgil Fuzzing Campaign

Random program generation and differential testing infrastructure for the
Virgil compiler (Aeneas), targeting the parser, semantic checker, interpreter,
and all compiled backends.

## Quick Start

```bash
# 1. Install Racket + Xsmith (once per machine)
./setup.sh

# 2. Build a compiler from current source. The campaign needs -test.update,
#    which the pre-built stable binaries do not have. On an arm64 mac:
V3C=$PWD/../../bin/stable/jar/Aeneas ../../bin/v3c-jar -output=/tmp/aeneas-jar \
    ../../aeneas/src/*/*.v3 $(cat ../../aeneas/DEPS | sed 's|^|../../|')
V3C=/tmp/aeneas-jar/Aeneas ../../bin/v3c-x86-64-darwin -output=/tmp/aeneas-x64 \
    ../../aeneas/src/*/*.v3 $(cat ../../aeneas/DEPS | sed 's|^|../../|')
export FUZZ_V3C=/tmp/aeneas-x64/Aeneas      # or bin/current/<host>/Aeneas after `make bootstrap`

# 3. Run the campaign (CTRL+C to stop, or give a duration)
./run-campaign.bash --duration 600
```

## Architecture

```
test/fuzz/
├── setup.sh              Install Racket and Xsmith
├── fuzz-common.bash      Shared helpers: compiler selection, batch runners, result parsing
├── run-campaign.bash     Top-level orchestrator (runs both workers)
├── fuzz-exec.bash        Differential testing worker
├── fuzz-parser.bash      Parser + semantic checker crash finder
├── minimize.bash         Delta-minimize a failing test case
├── promote.bash          Promote a minimized bug to the test suite
├── bugs/                 Saved bug reproducers (.v3 + .log; not committed)
└── virgil-smith/
    ├── virgil-smith.rkt  Xsmith program generator spec
    └── gen-batch.rkt     Generates a whole batch of programs in one process
```

## How It Works

### virgil-smith — Typed Program Generator

`virgil-smith.rkt` is an [Xsmith](https://docs.racket-lang.org/xsmith/) spec
that generates random, semantically valid Virgil programs. Xsmith uses reference
attribute grammars to guarantee type-correctness by construction.

**Phase 1 coverage** (current):

| Feature | Details |
|---------|---------|
| Types   | `int` (variables), `long`, `bool`, `Array<int>`, `(int, int)` (expressions) |
| Stmts   | `if`/`else`, `for (i < N)` bounded range, `var`, assign, expr-as-stmt |
| Exprs   | Arithmetic (+,-,*,/,%), comparisons, boolean &&/||/!, ternary `if(c,t,f)` |
| Safety  | Division guarded: `if(r==0, safe, a/r)` · Array index: `arr[(i & MAX_INT) % arr.length]` |
| Casts   | `long.!(int_expr)` widening · `int.view(long_expr)` bit-truncation |
| Arrays  | `Array<int>` literals, `.length`, safe indexed access |
| Tuples  | `(int, int)` construction, `.0` / `.1` field access |

Every program is a top-level `def main(a: int) -> int`, the same shape as the
tests in `test/core`, so compiled test binaries are named after the source file
and the standard test runners can execute them.

Loading Xsmith costs about two seconds, generating a program about ten
milliseconds, so `gen-batch.rkt` generates a whole batch per process:

```bash
racket virgil-smith/gen-batch.rkt --seed 100 --count 50 --out-dir /tmp/batch
racket virgil-smith/virgil-smith.rkt --seed 42     # a single program, to stdout
```

### fuzz-exec — Differential Testing

Works in batches (default 50 programs). Every step handles the whole batch in
one or two processes, so the cost per program is dominated by running it, not
by process startup:

1. Each generated program gets a `//@execute` header listing the test inputs
   with placeholder expectations.
2. `v3c -test -test.update batch/*.v3` runs each program in the reference
   interpreter and **rewrites the header with the actual results**. A program
   that fails to compile here is saved as `invalid-*` (a generator or checker
   problem); one that crashes the interpreter is saved as `v3i-crash-*`.
3. Each other interpreter configuration is run with `v3c -test <opts>` over
   the batch; the harness itself compares against the header.
4. For every compiled target and optimization level, the batch is compiled
   with `-multiple -target=<T>-test` and executed by the standard test runner
   (`test/config/test-<T>*`, or `test/bin/test-<T>` on hosts where
   `test/configure` did not link one), which also checks against the header.
   The (target, opts) jobs run concurrently.

**Configuration matrix per batch:**

| Kind | Configurations |
|------|----------------|
| Reference | `v3c -test -test.update` |
| Interpreter (`FUZZ_V3I_OPTS`) | `-O0` · `-ra` · `-ra -ma=false` · `-ra -maxd=4 -maxv=4` · `-ra -O3` · `-ra -O3 -licm` |
| Targets (`FUZZ_TARGETS`) | auto-detected: any of x86-64-linux, arm64-linux, x86-linux, x86-64-darwin, x86-darwin, jvm, wasm whose runner passes a probe |
| Opt levels (`FUZZ_OPTS`) | `-O0` · `-O1` (the default) · `-O2` · `-O3` · `-O2 -licm` · `-O3 -licm` |

Test inputs (`FUZZ_INPUTS`): `0 1 -1 2 3 7 42 100 1000 -1000 65536 2147483647 -2147483648`.

Each failing program is saved once as `bugs/<kind>-seed<N>.v3` with a
`bugs/<kind>-seed<N>.log` listing every configuration that failed and the
harness message. The `.v3` file carries the reference expectations in its
header, so it is directly usable as a `test/core` test. Kinds:

| Kind | Meaning |
|------|---------|
| `exec` | A configuration disagreed with the reference interpreter (miscompilation) |
| `compile` | A backend crashed or reported an internal error while compiling |
| `v3i-crash` | The reference interpreter itself crashed |
| `invalid` | The reference interpreter rejected the program: fix the generator (or the checker) |

Options: `--seed S`, `--batch N`, `--max-depth D` (Xsmith tree depth),
`--duration SECS`, `--max-programs N`, `--targets "x86-64-darwin jvm"`.
Environment variables above override the matrices; separate entries with `|`,
e.g. `FUZZ_OPTS="-O0|-O3 -licm"`.

### fuzz-parser — Parser + Semantic Checker Crash Finder

Takes valid virgil-smith programs (generated in batches) and applies random
text-level mutations, four mutants per program:

- **Syntax mode** (`//@parse`): delete/duplicate lines, replace identifiers
  with keywords, insert random tokens, swap characters.
- **Type mode** (`//@seman`): replace type annotations with wrong types, wrap
  variables and literals in ill-typed contexts (`!(x)`, `x.length`, `x(0)`,
  ...), plus structural mutations. Type mutations are aimed at the method
  body so they reach the type checker rather than the parser.

Each mutant is compiled with `v3c -test` under a timeout. Diagnostics are the
expected outcome; a bug is flagged if the compiler exits with a signal,
prints an internal error, or hangs. Bugs are saved as `bugs/parse-*.v3` or
`bugs/seman-*.v3` with a `.log`.

## Triage Workflow

```bash
# 1. Read the log to see which configurations failed
cat bugs/exec-seed42.log

# 2. Minimize it in one of those configurations. The oracle re-runs
#    -test.update on every candidate so the header stays correct.
./minimize.bash exec "x86-64-darwin -O2" bugs/exec-seed42.v3
./minimize.bash exec "v3i -ra -ma=false" bugs/exec-seed42.v3
./minimize.bash seman bugs/seman-seed7_2.v3

# 3. Review the minimized file
cat bugs/exec-seed42.min.v3

# 4. Promote to the permanent test suite (refreshes the header again)
./promote.bash bugs/exec-seed42.min.v3          # -> test/core/fuzzNN.v3

# 5. Until the bug is fixed, rename to fuzzNN.v3.fail so the suite stays green.
```

## Extending the Generator

The Xsmith spec is in `virgil-smith/virgil-smith.rkt`. To add new language
features:

1. Add grammar nodes to `add-to-grammar`
2. Add type constraints to `add-property virgil [type-info]`
3. Add rendering to `add-property virgil [render-node-info]`

Planned Phase 2 additions:
- Helper methods within the file (enables inter-method call testing and inlining)
- `long`-typed and `bool`-typed variables
- `Array<long>`, `Array<bool>` types; larger programs (more statements per block)
- Additional tuple types: `(int, long)`, `(bool, int)`
- Shifts, bitwise operators, and the fixed-width integer types (`u8`, `i16`, `u32`, `i64`, ...)
- `while` loops with bounded counters, `break`/`continue`
- String literals (read-only)

Planned Phase 3 additions:
- Simple classes with fields and methods
- ADT (`type`) declarations with `match`

## Environment Variables

| Variable | Effect |
|----------|--------|
| `FUZZ_V3C` | Compiler under test (falls back to `AENEAS_TEST`, then `bin/v3c`) |
| `FUZZ_TARGETS` | Targets for fuzz-exec (`auto` probes the host) |
| `FUZZ_OPTS`, `FUZZ_V3I_OPTS` | Optimization / interpreter configuration lists, `|`-separated |
| `FUZZ_INPUTS` | Inputs passed to `main` |
| `FUZZ_BUGS_DIR` | Where to save bugs (default `bugs/`) |
| `FUZZ_TIMEOUT` | Per-invocation timeout in seconds (default 60) |
| `VIRGIL_FUZZ_SEED` | Default seed for `run-campaign.bash` |

## Notes on Xsmith

The spec requires Racket ≥ 8.0 and the `xsmith` package. The `#lang clotho`
header enables Clotho's controllable randomness, which allows exact replay
of any program by seed.

The `binder-info` property teaches Xsmith which nodes create variable bindings
and their types. The `reference-info` property teaches it which nodes reference
those bindings. Xsmith automatically ensures that variable references only
appear where compatible bindings are in scope.

If `virgil-smith.rkt` fails to load with an Xsmith API error, check that the
installed Xsmith version matches the API used here. The spec was written against
the Xsmith API as documented at
https://docs.racket-lang.org/xsmith/Xsmith_Reference.html.
