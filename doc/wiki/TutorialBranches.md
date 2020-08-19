# Branches #

The basic control structures and comparison operators of Virgil III are very much like those in C/C++ and Java. If you're familiar with these languages, then skip to the end of this page for the summary.

## Integer Comparisons ##

Virgil supports the standard set of equality and inequality operators for the `int` type.

```

var x: int;
var y: int;
var a: bool = (x == y);	// equal
var b: bool = (x != y);	// not equal
var c: bool = (x < y);	// less than
var d: bool = (x <= y);	// less than or equal
var e: bool = (x > y);	// greater than
var f: bool = (x >= y);	// greater than or equal```

A similar set of operators are supported for the `byte` type.

```

var x: byte;
var y: byte;
var a: bool = (x == y);	// equal
var b: bool = (x != y);	// not equal
var c: bool = (x < y);	// less than
var d: bool = (x <= y);	// less than or equal
var e: bool = (x > y);	// greater than
var f: bool = (x >= y);	// greater than or equal```

## If Statements ##

If statements in Virgil are like those in Java. An `if` statement executes the associated statement or block if its condition evaluates to `true`. If statements require a condition expression of type `bool`. An `if` statement also optionally have an `else` clause the specifies the statement to execute if the condition is false. In either case, control resumes from the end of the `if` statement after the block is executed.

```

var b: bool;
def main() {
if (b) first();

if (b) first();
else second();

if (b) {
first();
first();
} else {
second();
second();
}
}
def first() {}
def second() {}```

The `else` statements chain together naturally like in other languages.

```

var b: bool;
def main() {
if (b) {
first();
first();
} else if (b) {
second();
second();
} else {
third();
third();
}
}
def first() {}
def second() {}
def third() {}```

## Standard Equality and Inequality ##

Every type in Virgil has both an equality `==` and inequality `!=` operator that compares two values of that type.

The array and string equality operators use _reference equality_, meaning that two values are only equal if they refer to the same object. The elements of an array are _never_ compared when using the standard equality operators.

```

var a = [1, 2];
var b = [1, 2];
var c = (a == b); // false; not reference equal
var d = (a == a); // true; reference equal```

```

var a = "hello";
var b = "hello";
var c = (a == b); // false; not reference equal
var d = (a == a); // true; reference equal```

For tuple types, the equality and inequality operators are _inductive_, which means that they apply recursively to the elements of the tuples. Two tuple values are equal if and only if their corresponding elements are equal.

```

var a = (1, 0);
var b = (1, 0);
var c = (a == b); // == true
var d = (a == (3, 4)); // == false```

Only one value exists for the `void` type. Thus equality comparisons between two `void` values are always `true`.

```

var x: void;
var y: void = ();
// with declared types
var a: bool = (x == y);	// always == true
var b: bool = (x != y);	// always == false
// with type inference
var c = (x == y);	// always == true
var d = (x != y);	// always == false```

## Summary ##

All types have built-in equality `==`, and inequality `!=` operators, even `void`. Tuples have _inductive_ equality and inequality operators, while arrays and other objects always use reference equality.
Virgil `if` statements require a condition of type `bool` and use the normal C/C++ curly brace `{ ... }` syntax.