# virgil: A Fast and Lightweight Systems Programming Language

```
def main() {
    System.puts("Virgil is fast and lightweight!\n");
}
```

Virgil is a programming language designed for building lightweight high-performance systems.
Its design blends functional and object-oriented programming paradigms for expressiveness and performance.
Virgil's compiler produces optimized, standalone native executables, WebAssembly modules, or JARs for the JVM.
For quick turnaround in testing and debugging, programs can also be run directly on a built-in interpreter.
It is well-suited to writing small and fast programs with little or no dependencies, which makes
it ideal for the lowest level of software systems.
On native targets, it includes features that allow building systems that talk directly to
kernels, dynamically generate machine code, implement garbage collection, etc.
It is currently being used for virtual machine and programming language
research, in particular the development of a next-generation WebAssembly virtual
machine, [Wizard](https://github.com/titzer/wizard-engine).

This repository includes the entire compiler, runtime system, some libraries,
tests, documentation and supporting code for Virgil's various compilation
targets.

## Language Design

Virgil focuses on balancing these main features in a statically-typed language:

  * Classes - for basic object-oriented programming
  * Functions - for small-scale reuse of functionality
  * Tuples - for efficient aggregation and uniform treatment of multi-argument functions
  * Type parameters - for powerful and clean abstraction over types
  * Algebraic data types - for easy building and matching of data structures

For more, read [this paper](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/41446.pdf).
Or see the [tutorial](doc/tutorial/Overview.md).
Or read up on [libraries](doc/tutorial/LibUtil.md).

## Supported Targets

Virgil can compile to native binaries for Linux or Darwin, to jar files for the
JVM, or to WebAssembly modules. Linux binaries can run successfully under
Windows using Window's Linux system call layer.
The compiler is naturally a cross-compiler, able to compile from any supported
platform to any other supported platform, so you need only be able to run on
one of these platforms in order to target any of the others.

* x86-darwin : 32-bit Darwin kernels (MacOS)
* x86-64-darwin : 64-bit Darwin kernels (MacOS)
* x86-linux : 32-bit Linux kernels
* x86-64-linux : 64-bit Linux kernels
* jar : JAR files for the Java Virtual Machine
* wasm : WebAssembly module for any Wasm engine

## Implementation

Virgil is fully self-hosted: its entire compiler and runtime system is
implemented in Virgil.
It was originally designed as a language for embedded systems, particularly
microcontrollers, but now supports more mainstream targets.
The compiler includes sophisticated whole-program optimizations that achieve
great performance and small binaries.
Native binaries compiled from your programs can be as small as a few hundred
bytes in size and consume just kilobytes of memory at runtime.
You can learn more in the [Implementation Guide](doc/impl/README.md).

## Documentation

The most up-to-date documentation is, as always, this repository!
Learn how to [get started](start/README.md) using Virgil and browse the [tutorial](doc/tutorial/Overview.md), where many [example](doc/tutorial/examples) programs exist.

### Research Papers

Six research papers have been published on Virgil.

* Bradley Wei Jie Teo and Ben L. Titzer. [Unboxing Virgil ADTs for Fun and Profit](https://dl.acm.org/doi/10.1145/3694848.3694857). In Proceedings of the Workshop Dedicated to Jens Palsberg on Occasion of of His 60th Birthday (JENSFEST 24). Pasadena, CA. October 2024.

* Ben L. Titzer. [Harmonizing Classes, Functions, Tuples and Type Parameters in Virgil III](https://dl.acm.org/doi/10.1145/2491956.2491962) \[[pdf](https://static.googleusercontent.com/media/research.google.com/sv//pubs/archive/41446.pdf)\]. In
Proceedings of the ACM Conference on Programming Language Design and Implementation
(PLDI '13). San Diego, CA. June 2013.

* Stephen Kou and Jens Palsberg. [From OO to FPGA: Fitting round objects into square hardware](https://dl.acm.org/doi/10.1145/1869459.1869470)? \[[pdf](https://web.cs.ucla.edu/~palsberg/paper/oopsla10.pdf)\] In
Proceedings of the ACM Conference on Object-Oriented Programming Systems, Languages and
Applications (OOPSLA '10). Reno, Nevada, 2010.

* Ben L. Titzer and Jens Palsberg. Vertical Object Layout and Compression for Fixed Heaps. In
Semantics and Algebra Specification. Pp. 376-408. 2009.

* Ben L. Titzer and Jens Palsberg. [Vertical Object Layout and Compression for Fixed Heaps](https://dl.acm.org/doi/10.1145/1289881.1289914) \[[pdf](https://web.cs.ucla.edu/~palsberg/paper/cases07.pdf)\]. In
Proceedings of the International Conference on Compilers, Architecture, and Synthesis for
Embedded Systems (CASES ’07). Salzburg, Austria. October 2007.

* Ben L. Titzer. [Virgil: Objects on the Head of a Pin](https://dl.acm.org/doi/10.1145/1167473.1167489) \[[pdf](https://escholarship.org/content/qt13r0q4fc/qt13r0q4fc.pdf)\]. In Proceedings of the 21 st Annual
Conference on Object-Oriented Systems, Languages, and Applications (OOPSLA '06). October 2006.

## License

Licensed under the Apache License, Version 2.0. ([rt/LICENSE](rt/LICENSE) or https://www.apache.org/licenses/LICENSE-2.0)
