# Pointers

Virgil is a fully self-hosted language.
Not only the entire compiler, but also the entire runtime system and garbage collector (GC) are written in Virgil!
Other than a small amount of manually-written assembly added by the compiler, there is no code in any other language needed to run a natively-compiled Virgil program.
But Virgil is a type-safe, memory-safe language, how is this possible?

The answer is that, on native targets, Virgil provides an unsafe `Pointer` type and associated operations that allow the Virgil runtime system and GC to be written in Virgil (rather than in a lower-level language or directly in assembly).

## What `Pointer` is used for in Virgil

There are three main uses of `Pointer` in Virgil's supporting code.

* system: calling the kernel to perform I/O, manipulate files, map memory, etc
* runtime: walking the stack to report a source-level stacktrace
* gc: walking the stack to find roots, trace the heap to find reachable objects, and copy/update live objects

First, Virgil provides the `System` component on all targets, which gives a very rudimentary system call layer to do I/O and manipulate files.
On native targets, the `System` component is written in Virgil source code and uses `Pointer`s and kernel system calls to implement its methods.

Second, the (very thin) Virgil runtime provides source-level stack traces upon program errors like `NullCheckException`, etc.
These stacktraces are printed out by the runtime system, which is also written in Virgil.
The runtime system walks the call stack and uses metadata from the compiler to reconstruct source locations for each native frame.

Third, the most complex, the Virgil garbage collector traces and copies the heap of the program, including live objects, as necessary, during program execution.
It also uses metadata from the compiler, such as the location of root references in native frames, the layout of heap objects, etc, to do this.

## What `Pointer` is *not* used for

`Pointer` is an all-powerful mechanism to read and write the native process's memory.
There are no safety checks.
In theory, it gives the ability to read or mutate any data in the program; we could build the "perfect" data structures laid out exactly how we want in memory.
In practice, applications should avoid using `Pointer`s and custom data structures for performance tuning in Virgil.
Rather, applications should use the safer, more convenient constructs like classes, closures, ADTs, arrays, ranges, etc.
`Pointer`s are only for interfacing lower-level software like an operating system kernel.

## How `Pointer`s work in Virgil

In Virgil, pointers are *untyped*, raw byte addresses.
They have these simple rules:

* there is only one `Pointer` type per target
* the `Pointer` type can be used anywhere any other Virgil type can be used
* the representation *size* of a `Pointer` is exactly the target address size (either 32 or 64 bits)
* `Pointer` values are not scanned or relocated by the garbage collector
* pointers support arithmetic (*add* and *subtract*)
* pointers support comparison (*equal*, *less-than*, etc)
* pointers support `load` and `store` operations to read/write Virgil values directly from/to memory

## `Pointer.SIZE` and `Pointer.NULL`

There are two important constants that are members of the `Pointer` type.

```
var x: int = Pointer.SIZE;      // the size, in bytes, of pointers on this target
var y: Pointer = Pointer.NULL;  // the null pointer, i.e. address 0
```

## `Pointer` arithmetic

As byte addresses, pointers support addition of a signed integer *offset*, and the subtraction of two pointers.
Since pointer size is target-specific, the type of the offset, or the result of subtracting two pointers, is different on different targets.

```
var n = Pointer.NULL;    // null pointer
var p1 = n + 66;         // add 66 (bytes) to a pointer
var p2 = n + 68L;        // add 68 (bytes) to a pointer (offset can be {long} on 64-bit)
var diffI: int = p - n;  // difference between pointers is of type {int} on 32-bit targets
var diffL: long = p - n; // difference between pointers is of type {long} on 64-bit targets
```

## `Pointer` comparison

As (unsigned) byte addresses, pointers can be compared with familiar inequality operators.
However, a `Pointer` cannot be *directly* compared to an integer.

```
var p: Pointer;
var q: Pointer;
var r1 = (p == q); // equality comparison between two pointers
var r2 = (p != q); // not equal comparison
var r3 = (p < q);  // less than
var r4 = (p <= q); // less than or equal
var r5 = (p > q);  // greater than
var r6 = (p >= q); // greater than or equal
var x = (p == 99); // ERROR: cannot compare pointer to integer
```

## `load` and `store` operations on `Pointer`

Virgil pointers are byte addresses that also support unchecked (potentially unsafe) access to memory with indiviual loads and stores.
With the `load` and `store` methods on a pointer, a program can read or write *any* Virgil values to that address.
Both methods have a type parameter indicating the type of the value to be loaded or stored.
With this mechanism, we can not only read or write primitive values to a pointer, but also other values, like pointers, or references (!).
This is dangerous and can not only interpret data as the wrong type, but potentially damage the heap, leading to a crash later.
It is recommended against doing dangerous loads/stores that subvert the type system.

```
var p: Pointer;
var x: int = p.load<int>();  // load an int (i32) from {p}
p.store<int>(33);	     // store an int into {p}

var y: string = p.load<string>(); // unchecked, raw reference load, dangerous!
```

Unlike C and C++, Virgil pointer accesses are generally *not* optimized by the compiler.
In particular, the Virgil compiler will not reorder or remove loads and stores written by the programmer.
Instead, pointer accesses are considered "volatile" and the compiler will dutifully perform them in program order.

## `cmpswp` on `Pointer`

Some native targets have an instruction for compare-and-swap, often used in implementing locks or other concurrent utilities.
Rather than offering higher-level mechanisms for concurrency (so far), Virgil just exposes this operation as a method on `Pointer`.
Eventually, Virgil will have higher-level concurrency constructs that are *implemented with* compare-and-swap.

```
var p: Pointer;
p.store<int>(33);
var x: bool = p.cmpswp(33, 44);  // returns true if {33} was atomically swapped to {44}
```

## Using arrays as buffers

Outside of implementing Virgil's own runtime system and garbage collector, the most common use case for `Pointer` is to interface to lower-level software like kernels for doing I/O.
In these cases, we typically use a Virgil array (often `Array<byte>`) as the underlying memory for exchange.
To get a pointer directly into the beginning of the contents of an array (i.e. element `0`), we can use `Pointer.atContents`.

```
def STDIN = 0;
def SYS_read = 3;
var buf = Array<byte>.new(128);
// call Linux kernel to read directly into {buf}
Linux.syscall(SYS_read, (STDIN, Pointer.atContents(buf), buf.length));
```

## Prefer off-heap `Range`s instead of `Pointer`s

Recently, Virgil added the [Ranges](Ranges.md).
Ranges are more general than arrays, as they can represent a subset of an array within a larger array.
But better than that, a `Range<T>` reference can be used to point to off-heap data, such as the execution stack, code, or memory-mapped regions.
Because Ranges are bounds checked, they are generally preferrable to raw `Pointer` values.
Like Arrays, the contents of Ranges can be pointed to (unsafely) with the `Pointer.atContents` operator.

```
def STDIN = 0;
def SYS_read = 3;
var buf = Array<byte>.new(128);
var range = buf[13 ... 88];
// call Linux kernel to read directly into {range}
Linux.syscall(SYS_read, (STDIN, Pointer.atContents(range), range.length));
```

## Pointers into other on-heap objects

Virgil supports experiments in new virtual machine designs.
In some circumstances, such virtual machines may need unsafe access to particular kinds of heap objects.
Recently, Virgil added a mechanism for obtaining pointers into the middle of heap objects.
Since pointers are *not* relocated by the GC, this is very dangerous.
They are documented here for completeness.

```
class C(x: int) { }
var c = C.new(33);
var ptr_c = Pointer.atObject(c);  // points at "beginning" of {c} object
var ptr_x = Pointer.atField(c.x); // points directly at {x} field of {c}

var a = Array<int>.new(3);
var ptr_length = Pointer.atLength(a);  // points at the {length} of {a}
var ptr_a_0 = Pointer.atElement(a, 0); // points at {a[0]}
var ptr_a_1 = Pointer.atElement(a, 1); // points at {a[1]}
var elem_size = ptr_a_1 - ptr_a_0;     // computes element size
```

## Targets where the `Pointer` type is exposed

The compiler exposes the `Pointer` type and associated operations only on these native targets:

* `x86-darwin` : 32-bit, `Pointer.SIZE == 4`
* `x86-64-darwin` : 64-bit, `Pointer.SIZE == 8`
* `x86-linux` : 32-bit, `Pointer.SIZE == 4`
* `x86-64-linux` : 64-bit, `Pointer.SIZE == 8`
* `wasm` : 32-bit, `Pointer.SIZE == 4`

These targets are not "native" and do not have the `Pointer` type:

* jvm/jar
* built-in interpreter (v3i)

