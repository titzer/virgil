# Getting Started #

To get started with Virgil III you will require:

  * 25MB of disk space
  * 200MB of RAM
  * bash shell
  * One of:
   - A Java 1.3 or later virtual machine
   - An x86 Linux machine
   - An x86 MacOS X machine

## Setup ##

Set up is super easy! Just clone this repository. No build step needed!

Optionally:

  * Add `$VIRGIL_PATH/bin` to your `$PATH` to use `v3c` and `v3c-*` commands from anywhere 
  * Add `$VIRGIL_PATH/bin/dev` to your `$PATH` if you are working on the compiler/runtime itself

## Commands ##

The commands in the `bin/` directory will automatically configure themselves when you first run them. You should find:

  * `v3i` - to run and test programs in the interpreter
  * `v3c` - directly invoke the Virgil compiler
  * `v3c-host` - compile to the host target (i.e. this computer)

Additional `v3c` commands allow you to compile programs for each supported target platform.

## Supported target platforms ##

Virgil includes a compiler that can produce binaries for various target platforms:

  * `jar` - Java Virtual Machine 1.3 or later
  * `x86-darwin` - Mac OS X 10.3 to 10.9 / 32-bit x86 processor
  * `x86-64-darwin` - Mac OS X 10.9 or later / 64-bit x86 processor
  * `x86-linux` - Linux 2.2 or later / 32-bit x86 processor
  * `x86-64-linux` - Linux 2.4 or later / 64-bit x86 processor
  * `wasm` - WebAssembly / 32-bit

For convenience, each platform has an associated v3c command that configures the compiler to generate a binary for that platform:

  * `v3c-jar` - compile for the JVM platform and produce .jar file and an executable wrapper script
  * `v3c-x86-darwin` - compile for the x86-darwin platform and produce an executable
  * `v3c-x86-64-darwin` - compile for the x86-64-darwin platform and produce an executable
  * `v3c-x86-linux` - compile for the x86-linux platform and produce an executable
  * `v3c-x86-64-linux` - compile for the x86-64-linux platform and produce an executable

See [BuildingAndRunningPrograms](BuildingAndRunningPrograms.md) to see more about how to compile and run Virgil programs.

## Tutorial ##

Learn more about the language through the [tutorial](Tutorial.md), which describes the main features by way of many example programs.
