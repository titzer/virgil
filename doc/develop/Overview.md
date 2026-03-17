# Overview

This tutorial explains tips and tricks for making changes to the Virgil compiler, language, runtime system, libraries, and tests.
It assumes basic knowledge about shell scripts and the Virgil programming language.

## Repository Organization

This repository includes compiler and runtime source code, tests, libraries, development tools, and sample applications.

 - Scripts to run the various tools (bin, bin/dev)
 - Pre-compiled binaries for the stable compiler, (bin/stable/*)
 - The compiler source code (aeneas/src)
 - Source code for the runtime system (rt/*) including garbage collector (rt/gc/*)
 - Source code for libraries (lib/*)
 - Tests for the compiler and runtime system (test/*) 
 - Source for various demo applications (apps/*)

## Tests and testing
 - v3c-dev versus aeneas bootstrap
 - aeneas test
 - v3c -test
 - test/dir/test.bash
 - Selecting a compiler with AENEAS_TEST=
 - Selecting targets with TEST_TARGETS=
 - Test results caching
 - Remote test targets (underdeveloped, broken?)
 - Stacktrace tests
 - GC tests
 - Runtime tests

## Debugging tools

 - Virgil interpreter (bin/dev/v3i)
   - print AST, SSA, and mach intermediate code
   - tracing execution
     - -trace
     - -trace-calls
     - -fatal-calls
   - print reachability analysis
 - Virgil debugger (bin/dev/v3db)
 - Using symbols on Linux and Wasm (Darwin unimplemented?)
 - Using gdb on Virgil binaries (Dwarf broken?)
 - Various print options to the compiler
   -print-vst
   -print-ssa=<filter>
   -print-mach=<filter>
   -print-regalloc
   -print-packing
   -print-cfg
   -print-bin
 - v3i profiler
 - v3i coverage tools
 