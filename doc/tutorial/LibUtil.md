# Virgil Libraries

Virgil is designed as a lightweight programming language with a clear separation between what is in the language versus what is in the libraries.
For example, in Virgil, there are _no_ built-in classes, enums, or algebraic data types.
The only built-in types are the primitives (`int`, `bool`, `void`, `float`, etc), and the type constructors (`Array`, functions, and tuples).
The `string` type is simply an alias for `Array<byte>`.

This is in contrast to languages like Java and C#, where many language concepts rely on support in the standard library and thus refer to certain built-in classes.

Instead, all classes, enums, and algebraic data types in Virgil are in fact, user-defined types.

## Exploring `lib/util`

Nevertheless, Virgil has a collection of useful utilities that are included in this repository, since many common tasks, like formatting strings, dealing with IO, building data structures, etc, recur often.
Generally, these utilities are not designed to meet all possible use cases, so they don't have every imaginable utility method and aren't designed to guard against every possible form of misuse.
They aren't "armored vehicles", but more like kitchen knives--they have a sharp end and a handle.

In `lib/util` we can find:

* [Vectors](lib/util/Vector.v3) - growable, indexable, appendable arrays with efficient storage
* String utilities - comparison, matching
* String formatting - print out data and strings in textual format
* IO - Read and write from files using in-memory buffers
* Decoding / Encoding - utilities for reading and writing binary data
* HashMap - efficient general mapping of key type to value type
* Lists - linked lists and associated utilities like `map`, `fold`, etc
* Array utils - additional utilities on arrays, like copying, ranges, `map`, etc
* Ints - read/write integers from strings
* Options - utilities for dealing with command line arguments
