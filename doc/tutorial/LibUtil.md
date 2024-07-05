# Virgil Libraries

Virgil is designed as a lightweight programming language with a clear separation between what is in the language versus what is in the libraries.
For example, in Virgil, the language provides constructs to define classes, enums, or algebraic data types, but there are no _built-in_ ones.
The only built-in types are the primitives (`int`, `bool`, `void`, `float`, etc), and the type constructors (`Array`, `Range`, functions, and tuples).
The `string` type is simply an alias for `Array<byte>`.

This is in contrast to languages like Java and C#, where many language concepts rely on support in the standard library and thus refer to certain built-in classes.

Instead, all classes, enums, and algebraic data types in Virgil are in fact, user-defined types.

## Exploring `lib/util`

Nevertheless, Virgil has a collection of useful utilities that are included in this repository, since many common tasks, like formatting strings, dealing with IO, building data structures, etc, recur often.
Generally, these utilities are not designed to meet all possible use cases, so they don't have every imaginable utility method and aren't designed to guard against every possible form of misuse.
They aren't "armored vehicles", but more like kitchen knives--they have a sharp end and a handle.

In `lib/util` we can find:

* [Vectors](../../lib/util/Vector.v3) - growable, indexable, appendable arrays with efficient storage
* [String utilities](../../lib/util/Strings.v3) - comparison, matching of strings
* [String formatting](../../lib/util/StringBuilder.v3) - print out data and strings in textual format
* [IO](../../lib/util/IO.v3) - Read and write from files using in-memory buffers
* [Decoding](../../lib/util/DataReader.v3) / [Encoding](../../lib/util/DataWriter.v3) - utilities for reading and writing binary data
* [HashMap](../../lib/util/Map.v3) - efficient general mapping of key type to value type
* [Lists](../../lib/util/List.v3) - linked lists and associated utilities like `map`, `fold`, etc
* Array utils - additional utilities on arrays, like copying, ranges, `map`, etc
* [Ints](../../lib/util/Ints.v3) and [Longs](../../lib/util/Longs.v3) - read/write integers from strings
* [Options](../../lib/util/Option.v3) - utilities for dealing with command line arguments
* [Globs](../../lib/util/GlobMatcher.v3) - utility for matching globs (strings with `?` and `*` wildcards)

## Demoing `lib/util`

Reading the source code of libraries is long and tedious, even when documented well.
While it may help to familiarize yourself with how Virgil code is written, libraries don't tell you how they are _supposed_ to be used.
For this, how about a demo?

Take a look at a [demo](../../apps/Demo) that has various sections on each of the utilities above.
The demo teaches you, on a class-by-class basis, how to use each utility.

