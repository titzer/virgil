# Virgil Compiler Design Overview

This document gives an overview of the design of Virgil's static optimizing compiler named `Aeneas`.
This document is intended for those working on adding language features, porting to new platforms, and improving performance of compiled programs, as well as those interested in learning about compiler design.
The compiler source code and its unit tests are under the top level [aeneas](../aeneas/) directory in this repository.
The the `v3c` command is a wrapper that calls a pre-compiled binary of `Aeneas`.

## Compiler and interpreter in one

While there is no such thing as an "interpreted" or "compiled" language, Virgil programs are usually statically compiled.
Their source is parsed, type-checked, transformed and optimized by a compiler, producing a binary form that is suitable for execution.
Because the Virgil language allows arbitrarily complicated code to run at initialization time, compilation necessarily requires an interpreter for the full language.
The interpreter can also be used to run programs directly, via a utility called [`v3i`](../bin/v3i).
Currently, this utility is just a wrapper around the `v3c` command; the interpreter functionality is part of `Aeneas`.

## Bootstrapping Aeneas

`Aeneas` is written in Virgil, meaning the Virgil language is self-hosted.
Because of this, we need a compiler for Virgil to run the compiler for Virgil!
This is known as the compiler bootstrapping problem, and the history and approach is covered in [Bootstrapping](Bootstrapping.md).
The short version is that several stable binaries of the `Aeneas` compiler are checked into this repository to avoid a dependency on an external compiler binary.
This repository is all that you need to work with, or indeed on, the Virgil language and compiler.

### `bin/stable/`

The `bin/stable/` directory contains checked-in binaries of the compiler for a set of stable target platforms.
A fresh checkout of Virgil will use these compilers with no bootstrapping step.

### `bin/bootstrap/`

Compiling the sources of the Aeneas compiler with `v3c-stable` produces an intermediate binary referred to as the *bootstrap compiler* (`v3c-bootstrap`) stored in `bin/bootstrap` directory.
It is not normally used except as an intermediate step to compile the source again.

### `bin/current`

Compiling the sources of the Aeneas compiler with `v3c-bootstrap` produces new executables referred to as the *current compiler* (`v3c-current`) stored in the `bin/current` directory.
Normally, when developing and testing the Aeneas compiler, we work with a fully-bootstrapped current compiler in `bin/current`.

### `bin/dev/v3c-dev`

Bootstrapping the Aeneas compiler is relatively fast, but still takes time (a second or two, depending on the host and target).
A delay of a second or two becomes noticeable when developing the compiler in rapid iteration, e.g. debugging.
To save development time, we often run the compiler as a regular program *on the Virgil interpreter* instead.
This is really simple; we just pass the source of the compiler to the built-in `v3i` command, which parses and typechecks the program and runs it, without needing to first generate target code.
It also saves a lot of time; the alias `v3c-dev`, which runs Aeneas on the interpreter, takes less than a hundred milliseconds to start (on native targets).
Running on the interpreter is much much slower than running compiled code, but is sufficiently fast to run most tests with reasonable speed, and the startup time savings usually makes up for it.
It is perfect for rapid iteration when debugging--so use `v3c-dev` whenever possible developing `Aeneas`--it will allow you to iterate faster!


## Compiler Phases

`Aeneas` is an optimizing compiler with multiple phases that mirror what one finds in traditional compiler textbooks.
It first 1) parses source code into abstract syntax trees, 2) performs semantic analysis by verifying and typechecking the code, 3) transforms the code through multiple intermediate representations, and then 4) produces binary code for a target platform.
It relies on no external tools such as an assembler or a linker; `Aeneas` produces binaries in a single step with one invocation of the compiler.

### Phase 1: Parsing

`Aeneas` parses source code by way of a scannerless hand-written recursive descent parser.
It is hand-written by necessity; no parser-generator framework generates Virgil source code.
The term "scannerless" means that the parser does not perform a separate lexical analysis phase that breaks the program into tokens.
Instead, the parser works directly on the input byte stream.

The parser is documented in further detail in [Parser.md](Parser.md).
In addition to enforcing the syntactic rules of the language, it produces a syntax tree for the next phases of the compiler.

### Phase 2: Semantic Analysis

`Aeneas` performs semantic analysis on syntax trees produced by the parser.
Covered in more detail in [Seman.md](Seman.md), this phase is done by the `Verifier` and enforces rules for the well-formedness of all definitions as well as the static type system that ensures Virgil programs are memory safe.

### Phase 3: IRs and Transformation

`Aeneas` translates the syntax trees of the program into several simpler internal forms for various purposes.
Classes, Components, ADTs, and other type definitions are translated into an internal form that makes their structure and inheritance explicit.
Code (i.e. the bodies of methods) is tranformed into per-method control flow graphs in SSA form, directly from syntax trees.
The initialized heap (obtained by running the program's initializers) is represented as records.


### Phase 4: Code generation

`Aeneas` has four different backends for different targets.
They were developed at different times as the compiler evolved and are, unfortunately, more different than they should be.

#### First backend: SSA -> JVM

The first backend developed targets the Java Virtual Machine (JVM).
Because the JVM accepts `.class` files that represent typed Java classes, the Virgil compiler translates Virgil class definitions, first-class functions, components, and ADTs into individual Java classes.
Because JVM bytecode is a stack machine, this backend includes a custom instruction selector, low-level IR, and stack reconstruction algorithm to generate relatively compact bytecode for the target.
The bulk of the complexity of this backend comes from the mismatch between the Java type system and Virgil's constructs such first-class functions (with co- and contra- variant types) as well as the initialized heap snapshot.
This translation predates `invokedynamic` and the translation of first-class functions is verbose and clunky.
This backend also shares the least functionality with the other backends; high-level operations such as a virtual dispatch and allocation are not lowered before code generation.

#### Second backend: SSA -> `x86-{darwin,linux}` (32-bit)

The second backend developed targets 32-bit X86 processors.
It requires high-level operations in the SSA code such as virtual dispatch and object allocation to first be lowered via the `MachLowering` phase that replaces high-level operations with machine-level operations but keeps SSA intact.
After machine lowering, this backend performs instruction-selection that produces a new low-level IR that uses virtual registers.
This IR is processed by a linear-scan register allocator which first performs liveness and then forward, single-pass register allocation without live-range splitting.
This backend has its own x86 assembler (factored into `lib/asm/x86/`) and produces both ELF files and Mach-O files.
It emits metadata for the runtime (`rt/native`, `rt/x86-{darwin,linux}`) and garbage collector (`rt/gc`)) that is part of the binary.

#### Third backend: SSA -> `WebAssembly` (linear memory)

The third backend developed targets WebAssembly.
Like the x86 backend, this backend requires first lowering high-level operations to machine-level operations.
It shares the machine lowering pass and the machine representation of the program `MachProgram` as well functionality for the runtime system.
However, it has its own, separate IR for instruction selection.
Since WebAssembly is a stack machine, this backend has a custom stackification algorithm (separate from the JVM).
The runtime system for this backend is in `rt/{wali,wave}`, representing two different system call interface alternatives, and the garbage collector is mostly shared with the other native backends (`x86[-64]-{darwin,linux}`).
This backend, however, uses a shadow stack for GC (i.e. a dedicated region of memory to spill references that otherwise be Wasm local variables).

#### Fourth backend: SSA -> `x86-64-{darwin,linux}` (64-bit)

The fourth, newest backend, is the x86-64 backend.
It shares machine lowering, the machine program representation, the runtime representation, and the representation of virtual registers with the other backens.
It has the most sophisticated instruction selector and has three different register allocators.
It shares the same low-level IR as the WebAssembly backend.
The garbage collector and most of the runtime is shared with the other native backends (x86 and Wasm).
Being the newest, this backend is the most well-designed.
Eventually, the JVM and 32-bit `x86` backends should be rewritten to use its IR.
This backend infrastructure is being used for a new `arm64` port, currently underway.
