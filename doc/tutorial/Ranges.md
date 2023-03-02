# Ranges #

Virgil III [arrays](Arrays.md) allow efficient storage of a fixed-size, indexable collection of values.
Ranges are a generalization of arrays that allow a referring to a smaller portion of an existing array.
In fact, an array can be implicitly promoted to a range so that APIs taking ranges can take arrays.
Like arrays, Ranges are zero-indexed, have a length which is fixed when the range is created, and all accesses are bounds checked at runtime.

```
// create a new array with Array<Type>.new(length)
var a: Array<int> = Array<int>.new(3);
var b: Array<bool> = Array<bool>.new(7);
var r: Range<int> = a; // implicit promotion of array to range
```

The syntax for range types mirrors that for arrays; they are simply written as `Range<T>`.
Unlike arrays, ranges are not created with `new`, but are created by either promoting an array or taking a subset of an array (or range).

## Literals ##

As we saw before, we can use the `[ ... ]` syntax for creating array literals.
With automatic promotion to range, we can use array literals where ranges are expected.

```
// [ ... ] creates an array of uniform type
var a: Array<int> = [0, 1, 2];
var b: Range<bool> = [true, false, true]; // implicit promotion from array to range
var c: Range<byte> = [];                  // implicit promotion from array to range
```

By default, array literals without explicit types will be considered arrays (not ranges).
Usually, the type of the array can be inferred, either directly from the element expressions themselves, or from the surrounding context.

```
var d = [9, 4, 5];       // Array<int>
var d: Array<byte> = []; // new empty byte array
```

## Range expressions

Virgil III offers range expressions that denote ranges for a smaller portion of an existing array or range.
The resulting range is an _alias_ in that writes to the underlying array or range will be reflected in the subrange.
There are three main syntactic forms for range expressions.

### Range `from` `...` `to` expressions

The syntax `expr[start ... end]` denotes a subrange of `expr` starting at index `start` and ending at index `end`.
The expression `expr` can be either an array or a range.
The end index is _exclusive_.
```
var a: Array<byte> = [99, 44];
var everything: Range<byte> = a[0 ... a.length];            // entire range of a
var firstelem: Range<byte>  = a[0 ... 1];                   // range from 0 to 1, not including 1
var lastelem: Range<byte>   = a[a.length - 1 ... a.length]; // range from 1 to 2, not including 2
var subrange: Range<byte>   = everything[0 ... 2];          // take a subrange of a range
```

### Range `from` `...` expressions

A convenient shorthand for ranges that extend to all the way to the end omits the `end` index above:
```
var a: Array<byte> = [99, 44];
var everything: Range<byte> = a[0 ...];            // entire range of a
var tail: Range<byte>       = a[1 ...];            // skip the first element
var lastelem: Range<byte>   = a[a.length - 1 ...]; // range from 1 to 2, not including 2
```

### Range `from` `..+` `length` expressions

Another syntactic form allows specifying a range from a start index plus a length (rather than the end index).
The syntax uses the `..+` operator to evoke the idea of _adding_ the length to the start index to get the end.
```
var a = [0, 1, 2, 3, 4];
var r = a[0 ..+ 2];      // start at index 0, length 2
```

## Bounds checking

When evaluating a range expression, runtime bounds checks are executed to ensure that the entire subrange will be in bounds.
```
var a = [0, 1, 2, 3];
var r = a[0 ... 5];   // will fail with !BoundsCheckException
```

## Range aliasing and identity

Ranges in Virgil do not have identity that is separate from their underlying storage.
Thus two ranges that refer to the same underlying storage will compare as equal.
```
var a = [0, 1, 2, 3, 4, 5];
var r1 = a[3 ...];
var r2 = a[3 ...];
var r3 = a[4 ...];

var x = r1 == r2; // true; both refer to {a}, indices {3} to {6}.
var x = r1 == r3; // false; indices mismatch
```

## Reading and writing elements ##

Reading and writing elements of ranges uses the `[ ... ]` syntax like regular Virgil arrays.
The index expression into the array must be of an integer type (i.e. not specifically just `int`, any type `iN` or `uN`).
```
var a: Range<bool> = [true, false];
var x: bool = a[0];    // array element read
var y: bool = a[0uL];  // array element read of very large index
var z: int = a.length; // read of range length
```

```
def main() {
    var x: Range<int> = Array<int>.new(3);
    x[0] = 11; // assignment to array element
    var y = x[0];
}
```

## Bounds and null checks ##

Accesses of Virgil ranges are dynamically checked against the bounds, just like Virgil arrays.
An access of a `null` range results in a `!NullCheckException` and using an index out of the range `[0, range.length)` will result in a `!BoundsCheckException`.

```
def main() {
    var a: Range<int>; // default value is null
    a[0] = 0;          // produces !NullCheckException
}
```

```
def main() {
    var x: Range<int> = Array<int>.new(3);
    x[3] = 11;                             // produces !BoundsCheckException
    var y = x[0];
}
```

## Iteration with `for`-each form

Ranges can be used in the `for`-each loop construct to succinctly describe iterating (in increasing order) over the elements of a range.

```
def sumTail(a: Array<int>) -> int {
    var sum = 0;
    for (x in a[1 ...]) sum += x;   // iterate over subrange, skipping element 0
    return sum;
}
```

## Composability ##

Like Virgil arrays, any legal type can be used as the element type, including `void`, tuples, etc.

```
// if T is a legal type, then Range<T> is a legal type, even T=void
var a: Range<void> = [()];
var b: Range<void> = [(), (), ()];
var c: Range<(int, int)> = [(33, 44)];
```

## Not co-variant ##

Virgil ranges, like Virgil arrays, are _not_ co-variantly typed. See the section on [variance](Variance.md) for more details.

## Performance expectations

Ranges in Virgil are effectively tuples of three values: an underlying array, a start index, and a length.
Like other tuples in Virgil, these three values will be unboxed (i.e. flattened or _normalized_).
Unlike a Go (slice)[https://go.dev/tour/moretypes/7], a range is not an object on the heap with a (mutable) length and a capacity.

- Evaluating a range expression does not need to allocate storage on the garbage-collected heap.
  (That makes them suitable for high-performance, allocation-free algorithms that do not create GC pressure.)
- Accessing range elements is constant-time, like arrays.
  (The index is bounds-checked against the length, and then the start index is added. This is just one more
   machine instruction versus a raw array.)
- Accessing the length is constant-time.
  (This is simply a projection of the three-tuple.)
- Evaluating a range expression is constant-time.
  (The start and end indices are bounds checked, then a three-value tuple is the result).
  