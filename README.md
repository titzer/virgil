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

Five research papers have been published on Virgil.

* Ben L. Titzer. [Harmonizing Classes, Functions, Tuples and Type Parameters in Virgil III](https://dl.acm.org/doi/10.1145/2491956.2491962). In
Proceedings of the ACM Conference on Programming Language Design and Implementation
(PLDI '13). San Diego, CA. June 2013.

* Stephen Kou and Jens Palsberg. [From OO to FPGA: Fitting round objects into square hardware](https://dl.acm.org/doi/10.1145/1869459.1869470)? In
Proceedings of the ACM Conference on Object-Oriented Programming Systems, Languages and
Applications (OOPSLA '10). Reno, Nevada, 2010.

* Ben L. Titzer and Jens Palsberg. Vertical Object Layout and Compression for Fixed Heaps. In
Semantics and Algebra Specification. Pp. 376-408. 2009.

* Ben L. Titzer and Jens Palsberg. [Vertical Object Layout and Compression for Fixed Heaps](https://dl.acm.org/doi/10.1145/1289881.1289914). In
Proceedings of the International Conference on Compilers, Architecture, and Synthesis for
Embedded Systems (CASES ’07). Salzburg, Austria. October 2007.

* Ben L. Titzer. [Virgil: Objects on the Head of a Pin](https://dl.acm.org/doi/10.1145/1167473.1167489). In Proceedings of the 21 st Annual
Conference on Object-Oriented Systems, Languages, and Applications (OOPSLA '06). October 2006.

### Tutorial programs

There are lots of example programs in [doc/tutorial](doc/tutorial).

## License

Licensed under the Apache License, Version 2.0. ([rt/LICENSE](LICENSE) or https://www.apache.org/licenses/LICENSE-2.0)

