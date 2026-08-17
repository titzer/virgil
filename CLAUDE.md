# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

- **Language syntax** (grammar): `doc/grammar-claude.md`
- **Practical guide** (classes, ADTs, match, visibility, integer types, casts, method chaining, test format, optimizer): `doc/claude-guide.md`
- **Full tutorial**: `doc/tutorial/`

## Project Overview

Virgil is a statically-typed, self-hosted systems programming language. The entire compiler (called **Aeneas**), runtime, GC, and libraries are written in Virgil itself. The compiler is a whole-program optimizing compiler that produces native binaries (ELF/Mach-O), JARs, or WebAssembly modules with no separate linking step.

## Build Commands

```bash
# Bootstrap the compiler (compile current source with stable, then with itself)
make bootstrap

# Build utility tools (vctags, progress, nu, np, demangle)
make utils

# Build a stable (non-debug) compiler
make stable

# Clean build artifacts
make clean
```

Bootstrap is required when you've made changes to compiler source (`aeneas/src/`) and want to use those changes. The `bin/stable/` binaries are pre-built; `bin/bootstrap/` and `bin/current/` are produced by bootstrapping.

## Running Programs

```bash
# Add bin/ to PATH first
export PATH=$PATH:$(pwd)/bin
export PATH=$PATH:$(pwd)/bin/dev  # for aeneas dev tool

# Run directly in the interpreter (no compilation)
v3i apps/HelloWorld/HelloWorld.v3

# Compile to native (use platform-specific script)
v3c-x86-64-linux apps/HelloWorld/HelloWorld.v3

# Compile to other targets, with runtime system and GC: v3c-x86-linux, v3c-x86-64-darwin, v3c-arm64-linux, v3c-jar, v3c-wasm
# Compile to other targets, without runtime: v3c -target=x86-linux, v3c -target=x86-linux-test, 

# Run the current compiler on the stable compiler's interpreter, which skips a build step
v3c-dev
```

## Testing

```bash
# Run simple tests on the interpreter
v3c -test foo.v3 bar.v3

# Run all test suites
./test/all.bash

# Run a specific subset of test suites (pass suite names as args)
./test/all.bash unit core cast variants

# Run a single test suite directly
cd test/unit && ./test.bash
cd test/core && ./test.bash
cd test/asm/x86-64 && ./test.bash

# Diagnose test failures
./test/diagnose.bash
```

**Key environment variables for testing:**
- `TEST_HOST` — override assumed host platform
- `TEST_TARGETS` — override set of targets (e.g., `"v3i x86-64-linux"`)
- `AENEAS_TEST` — use a specific compiler binary (`stable`, `bootstrap`, `current`, or path: current is default)
- `V3C_OPTS` — add extra compiler options

## Architecture

### Compiler Pipeline (`aeneas/src/`)

Source flows through these phases in order:

1. **Parser** (`vst/`) — lexes and parses `.v3` source files into a Virgil Syntax Tree (VST)
2. **Semantic Analysis** (`vst/Verifier.v3`) — type-checking, name resolution, semantic validation
3. **SSA Generation** (`ssa/VstSsaGen.v3`) — lowers VST to Static Single Assignment form
4. **SSA Optimization** (`ssa/SsaOptimizer.v3`) — inlining, constant folding, devirtualization, etc.
5. **IR Normalization** (`ir/SsaNormalizer.v3`) — computes reachable program and lowers to target-normalized IR
6. **Machine Lowering** (`mach/MachLowering.v3`) - replaces mid-level operations with machine operations
6. **Code Generation** — target-specific backends emit machine code
7. **Binary Emission** (`exe/`) — writes ELF (Linux), Mach-O (Darwin), JAR, or `.wasm` files

### Key Subdirectories of `aeneas/src/`

| Directory | Purpose |
|-----------|---------|
| `vst/` | Parser, AST nodes, type checker, semantic verifier |
| `types/` | Type representation and type system primitives |
| `v3/` | Virgil language-specific type and program representation |
| `ir/` | Intermediate representation, normalization passes |
| `ssa/` | SSA form, optimization passes, register allocation prep |
| `mach/` | Machine-level backend: register allocation, shadow stacks, calling conventions |
| `x86/`, `x86-64/` | x86 and x86-64 assemblers and code generators |
| `arm64/` | ARM64 assembler and code generator |
| `jvm/` | JVM bytecode emitter |
| `wasm/` | WebAssembly module emitter (linear and GC variants) |
| `exe/` | ELF and Mach-O binary writers |
| `debug/` | DWARF debug info generation |
| `core/` | Core program representation (components, methods, fields) |
| `os/` | OS-specific syscall interfaces |
| `util/` | Compiler-internal utilities |
| `main/` | Entry point and compiler driver |

### Runtime System (`rt/`)

The runtime is compiled together with user programs (no separate runtime linking).

### Standard Libraries (`lib/`)

Optional utility libraries, not part of the language core. Programs must explicitly include these files at compilation.

### Compiler Binaries (`bin/`)

- `bin/stable/<platform>/Aeneas` — pre-built stable compiler binaries
- `bin/bootstrap/<platform>/Aeneas` — compiler compiled by stable (produced by `make bootstrap`)
- `bin/current/<platform>/Aeneas` — compiler compiled by bootstrap (produced by `make bootstrap`)
- `bin/v3c`, `bin/v3i`, `bin/v3c-<target>` — wrapper scripts that invoke the appropriate binary

### Bootstrapping

The `make bootstrap` command runs `bin/dev/aeneas bootstrap`, which:
1. Compiles `aeneas/src/` with `bin/stable/<host>/Aeneas` → produces `bin/bootstrap/`
2. Compiles `aeneas/src/` with `bin/bootstrap/<host>/Aeneas` → produces `bin/current/`
3. test/bootstrap/test.sh Verifies the two outputs are bit-for-bit identical (fixpoint check)

### Compiler Invocation

The compiler takes all source files of a program at once (whole-program compilation). Example:
```bash
# Invoke compiler directly
v3c -target=x86-64-linux -output=/tmp/ file1.v3 file2.v3 ...

# Use platform wrapper (includes runtime sources automatically)
v3c-x86-64-linux -output=/tmp/ file1.v3 file2.v3 ...
```

The `aeneas/DEPS` file lists the standard library sources that the compiler itself depends on.
