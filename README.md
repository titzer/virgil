# virgil: A Fast and Lightweight Programming Language

Virgil is a programming language designed for fast, dependency-free programs.
Its design blends functional and object-oriented programming paradigms for expressiveness
without a lot of overhead, either syntactically or at runtime.
Its implementation is focused primarily on static compilation to produce native
executables that are standalone.
That makes it ideal for building certain kinds of programs like compilers and virtual
machines.
Virgil can compile to x86 binaries for Linux or Darwin, to jar files for the JVM,
or to WebAssembly.

## Implementation

Virgil is fully self-hosted: its entire compiler and runtime system is implemented
in Virgil.
It can bootstrap (i.e. compiler compiles itself and all runtime code) on any of its
target platforms.
It is currently being used for virtual machine and programming language research.

This repository includes the entire compiler, runtime system, tests, and supporting code
for Virgil's various compilation targets.


## Documentation

The most up-to-date documentation is, as always, the implementation in this repository!

### Google Code Project

An slightly out-of-date tutorial from the defunct [Google Code Project](https://code.google.com/archive/p/virgil/).
Some syntax has changed and Virgil now supports algebraic data types, enums, floating point, and compiles to more targets.

### Research Papers

Four research papers have been published on Virgil.

### Tutorial programs

## License

Licensed under the Apache License, Version 2.0. ([rt/LICENSE](LICENSE) or https://www.apache.org/licenses/LICENSE-2.0)

