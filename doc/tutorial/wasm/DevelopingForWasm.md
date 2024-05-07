# Developing with Virgil for Wasm

Virgil supports a variety of compilation targets, including WebAssembly (Wasm), a portable low-level bytecode that can run in Webpages and elsewhere.
Targeting Wasm from Virgil is easy; just use the right compilation target and define imports from the outside world.
Wasm modules generated from Virgil can then be integrated into a Wasm environment as you see fit.

## The `-target=wasm` flag

The Virgil compiler (aka `v3c` or `Aeneas`) supports Wasm as a target out of the box.
Passing the `-target=wasm` flag selects the Wasm compiler code generator, which will produce a `.wasm` file as a result of compilation.
For programs with no dependencies on system APIs, this works like so:

> ReturnZero.v3:
```
def main() -> int {
    return 0;
}
```

```
% v3c -target=wasm ReturnZero.v3
% wasm-objdump ReturnZero.wasm

ReturnZero.wasm:	file format wasm 0x1

Code Disassembly:

000048 func[0] <main>:
 000049: 41 00                      | i32.const 0
 00004b: 0b                         | end
```

Thus, we can generate standalone (we might say *barebones*) Wasm programs from Virgil easily.

## The `v3c-wave` script

For larger Virgil programs, a more complete Wasm solution is needed.
For example, as seen in other tutorials, Virgil offers a small set of system APIs supported on all targets via the `System` component, which offers basics like standard in/out and file access.
This is a minimum for command-line utilities such as the compiler itself.

The `v3c-wave` script offers a nearly feature-complete target for Wasm.
This "wave" target stands for "WebAssembly Virgil Environment" and compiles Virgil to WebAssembly using a small set of Wasm imports tailored to Virgil's needs.
The `v3c-wave` script mirrors the `v3c-x86-linux` and other target scripts and compiles your program along with a runtime system, garbage collector, and `System` implementation into a `.wasm` module that can be run on both `node` and `Wizard`.

> HelloWorld.v3
```
def main() {
	System.puts("Hello World!\n");
}
```

This program can be compiled easily:

```
% virgil/bin/dev/v3c-wave HelloWorld.v3
% ls HelloWorld*
HelloWorld	HelloWorld.v3	HelloWorld.wasm
```

Notice that in addition to the `HelloWorld.wasm` binary which has been generated, an *executable* named `HelloWorld` has been generated.
This executable is a shell script, i.e. a wrapper, that invokes a WebAssembly engine to run the program.
By default, the generated script will use [Wizard](https://github.com/titzer/wizard-engine) (i.e. the `wizeng` command).
If you have Wizard installed, you should be able to execute this directly:

```
% ./HelloWorld
Hello World!
```

Note that we can also run `HelloWorld.wasm` on `node` using a helper script `wave.node.js`, which is implemented in JavaScript.
The JavaScript helper code is in `virgil/rt/wave` and contains the implementation of imported functions.

```
% node virgil/rt/wave/wave.node.js ./HelloWorld.wasm
Hello World!
```

(Note that the shell script wrapper can be edited, either manually or automatically, to run `node` with the JavaScript helper).

### Stacktraces on the `v3c-wave` target

The "wave" target for Virgil is *nearly* feature complete.
It offers the standard I/O features of `System` as well as a runtime system with a precise, moving garbage collector.
(The garbage collector uses a shadow stack to find and update roots on the execution stack).
One drawback to the Wasm target is that it does not yet print source-level stack traces with line and column, so it can be more difficult to debug program crashes on Wasm.

> Stacktrace on Virgil interpreter:
```
% v3i NullCheck.v3
!NullCheckException
	in sum() [NullCheck.v3 @ 6:19]
	in main() [NullCheck.v3 @ 2:19]
```

> Stacktrace on native targets:
```
% v3c-x86-linux NullCheck.v3
% ./NullCheck
!NullCheckException
	in sum() [NullCheck.v3 @ 6:19]
	in main() [NullCheck.v3 @ 2:19]
```

> Stacktrace on Wasm target (running on Wizard):
```
% v3c-wave -symbols NullCheck.v3
% ./NullCheck
<wasm func ".entry"> +6
  <wasm func "NullCheck.main"> +3
    <wasm func "NullCheck.sum"> +8
      !trap[UNREACHABLE]
```

(note that `+3` and `+8` are bytecode offsets, not lines).

> Stacktrace on Wasm target (running on node):
```
% v3c-wave -symbols NullCheck.v3
% ./NullCheck
wasm://wasm/9875f20a:1


RuntimeError: unreachable
    at NullCheck.sum (<anonymous>:wasm-function[9]:0x28d)
    at NullCheck.main (<anonymous>:wasm-function[6]:0x188)
    at .entry (<anonymous>:wasm-function[5]:0x17d)
    at Object.<anonymous> (/Users/titzer/virgil/rt/wave/wave.node.js:91:20)
    at Module._compile (node:internal/modules/cjs/loader:1092:14)
    at Object.Module._extensions..js (node:internal/modules/cjs/loader:1121:10)
    at Module.load (node:internal/modules/cjs/loader:972:32)
    at Function.Module._load (node:internal/modules/cjs/loader:813:14)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:76:12)
    at node:internal/main/run_main_module:17:47
```

Note that safety checks such as `NullCheck` and `BoundsCheck` may show up as "unreachable" on Wasm targets.

## Defining your own Wasm imports

The Wasm target for Virgil supports both importing user-defined Wasm functions as well as exporting Virgil functions.
We can use the import/export mechanism of Virgil to generate `.wasm` programs that use APIs that are supplied by a specific host environment, such as JavaScript.

> ImportExport.v3:
```
import component MyImports {
	def print(x: int) -> int;
}

def main() {
}

export def printPlus33(x: int) {
	MyImports.print(x + 33);
}
```

Below we can see (excerpted) output from disassembling the result of compiling this program to a `.wasm`, showing its imports and exports:

```
% v3c -target=wasm ImportExport.v3
% wasm-objdump -x ImportExport.wasm
ImportExport.wasm:	file format wasm 0x1

Section Details:

Type[4]:
 - type[0] (i32) -> i32
 - type[1] () -> nil
 - type[2] (i32) -> nil
 - type[3] (i32, i32) -> i32
Import[1]:
 - func[0] sig=0 <MyImports.print> <- MyImports.print

...

Export[3]:
 - func[1] <main> -> "main"
 - memory[0] -> "memory"
 - func[2] <printPlus33> -> "printPlus33"

...

```

A fully functional example of how to use Virgil to create Wasm for the Web can be see in the (WebMandelbrot application)[apps/WebMandelbrot].
Of course, using the import/export mechanism of Virgil, we can define programs that use any core Wasm API, including WASI!
