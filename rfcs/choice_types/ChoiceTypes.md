# Introduction

Errors are a pervasive part of programming.
A programming language should have just enough features to allow programmers to write terse, robust code that handles all possible errors gracefully without cluttering the logic of successful execution.

# Choice Types

This RFC proposes a Virgil language mechanism called *choice types*, written `A|B`, that allows programmers to define and pattern-match values that consist of *either* a value of type `A` or value of type `B`.
There are no restrictions on the types `A` or `B` or the values of `A` that can be put into such a union.
There is one special case, however: `A|A` is equivalent to the type `A`, for all types `A`.

## Implicit promotion, not subtyping

A choice type `A|B` is *not* a supertype of either of its constituent types, as it may be represented differently than either of them, e.g. by including a tag, which could be as small as a single bit.
However, values of type `A` and `B` can be *implicitly promoted* to the choice type in source code expressions.
Thus it is not necessary to "wrap" a value to use it where a choice type is expected.

```
def foo() {
    var x: int|string;
    x = 99;       // OK, implicit promotion
    x = "hello";  // OK, implicit promotion
}
```

## Terse pattern matching

Choice types are meant to allow extremely terse pattern matching, so that error-handling code stays brief.
For this, the short-circuiting boolean conditional operators operators `||` and `&&` are overloaded to pattern-match choices.

For example, consider a hash function that accepts either integers or strings:

```
def hash(a: int|string) {
    return a || hash(that);
}
def hash_string(s: string) -> int {
    ...
}
def x = hash(33);          // OK, implicit promotion
def y = hash("my string"); // OK, implicit promotion
```

How does terse expression pattern matching work?
Suppose we have an expression `a` of type `A|B`.
The expression `a||expr(that)` pattern-matches on a value choice type and evaluates like so:
  * the overall expression returns `a` if the input value is of type `A`, without evaluating `expr(that)`
  * otherwise the input must be of type `B` and it returns the result of evaluating `expr(that)` where the keyword `that` is bound to the input value and has type `B`
  * the *type* of the overall expression `a||expr(that)` is then `A|C` if the type of `expr(that)` is `C`

## Using choices for errors and error handling

The design of choice types admits nice-looking error handling that doesn't clutter up code with exception handlers.
This is easy and extensible, since the right-hand-side of a choice type can be a type representing an error.

```
// Library
type Fd { ... }
type Error {
    case FileNotFound(path: string);
    case PermissionDenied;
    case FileClosed;
}
def open(path: string) -> Fd|Error;
def read(fd: Fd) -> Array<byte>|Error;

// Application
def load(path: string) -> Array<byte>|Error {
    var fd = open(path) || return that;
    var data = read(fd) || return that;
    ...
}
```

In this example, we can see a sketch of a little file API.
Since errors can occur with both opening or reading files, these library methods return a choice between either success or an error type they've defined.
The `||` operator is used to pattern-match for success and return early (with the error value) upon failure.
This allows the caller to handle errors.
Unlike exceptions however, this code doesn't *throw* the error, which could cause the caller to be abruptly terminated; instead the caller gets a *value* that contains the error, which can be handled, pattern-matched on, put into a data structure, passed around, etc, like all other program values.
And unlike wrapping errors in ADTs, where the syntactic overhead of matching tempts programmers to add a method to the ADT to force it to crash, throw, or panic, choice types matched tersely inline.

### Intentionally less general than union types

Choice types are intentionally less general than full union types.
They are restricted in that they are *ordered* (i.e. `A|B` is **not** equivalent to `B|A`) and *binary* (i.e. `A|B|C` is interpreted as `(A|B)|C` and **not** equivalent to `A|(B|C)`, so the `|` type operator is not associative).

### Lighter-weight than ADTs

Choice types are less general than full algebraic data types (which of course Virgil does have).
They offer a terser syntax that lends themselves well to expressing errors and error handling.

The choice type `A|B` could be expressed as a Virgil ADT like so:

```
type MyAorB {
    case MyA(val: A);
    case MyB(val: B);
}
```

The names `MyAorB`, `MyA`, `MyB`, and `val` are "fresh" and immaterial to the structure of the type they declare.

## Why are ADTs insufficient?

ADTs aren't *insufficient* for this task, they are just clunky and verbose.
They do give the ability to define any kind of custom error type as the union of (multiple) success cases and (multiple) error cases.
However, most languages end up build APIs with a standard polymorphic error type (such as `Maybe<T>` or `Result<T>`) that all APIs then use.
That verbosity has led a lot of programming languages with such types to add the equivalent of a `force()` or `unwrap()` method that will cause a dynamic error.
Programs that use these methods are **error-prone** (pun intended)!

Instead, with choice types, the error part of a choice can be easily eliminated with the `||` operator, using early returns or helper functions.

## Why not exceptions?

Choice types and pattern-matching on choice types allow errors to be treated as *values* and *types*, which all of the language constructs are designed to manipulate.
This allows error-handling code to be factored out in exactly the same way as logic for other values (i.e. using *functions* !?).
Errors can be "saved for later" or transformed into other errors, reported, or recorded, and when errors have been dealt with, the success value remains.

Choice types allow using polymorphism to process errors independent of success values.
We can write error handling routines such as:

```
def reportIOError<T>(v: T|IOError, defval: T) -> T {
    // return either the success of v, or defval
    return v || ((reportIOErrorToUser(that), defval).1);
}
def reportIOErrorToUser(e: IOError) {
    match (e) {
        FileNotFound(path) => ...;
        PermissionDenied => ...;
    }
}
def hashFile(path: string) -> int|IOError;
def safeHashFile(path: string) -> int {
    def DEFAULT_HASH = -1;
    return reportIOError(hashFile(path), DEFAULT_HASH);
}
```

We can then build even higher-level utilities like so:
%TODO

```
def safeIOOperation<P, R>(f: P -> R|IOError, defval: R) -> P -> R {
    return compose(f, reportIOError<R>(_, defval));
}

def safeLoad = safeIOOperation(unsafeLoad, null);
```

### Implementation notes

It is the Virgil compiler's responsibility to implement choice types efficiently--e.g. to unbox their representation and introduce a tag (consisting of at most one bit) when necessary.
The exact representation may depend on the target machine's capabilities.
For example, non-overlapping references types `A` and `B`, the compiler can often elide a tag and represent a union value as a single reference word.
The Virgil compiler has some support for annotations that guide its choice of ADT representations.
These mechanisms form the basis of the internal implementation strategy that choose representations for choice types.