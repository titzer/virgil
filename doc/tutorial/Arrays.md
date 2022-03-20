# Arrays #

Virgil III provides arrays for efficient storage of a fixed-size, indexable collection of values. Arrays are zero-indexed, have a length which is fixed at allocation time, and all accesses are bounds checked at runtime.

```
// create a new array with Array<Type>.new(length)
var a: Array<int> = Array<int>.new(3);
var b: Array<bool> = Array<bool>.new(7);
// with inferred type
var c = Array<bool>.new(7);
```

Unlike most other languages, Virgil has no special syntax for array types. Instead, they are simply written as `Array<T>`. To allocate a new array, we use the `new` keyword as if it were a _member_ of the array type. The elements of the array will be initialized to the default value for the element type.

## Literals ##

We can also use the `[ ... ]` syntax for creating array literals. The expressions enclosed in the brackets are evaluated, a new array of the appropriate length is created, and that array is initialized with the elements.

```
// [ ... ] creates an array of uniform type
var a: Array<int> = [0, 1, 2];
var b: Array<bool> = [true, false, true];
var c: Array<byte> = [];
```

Usually, the type of the array can be inferred, either directly from the element expressions themselves, or from the surrounding context.

```
var d = [9, 4, 5];       // Array<int>
var d: Array<byte> = []; // new empty byte array
```

## Multi-dimensional Arrays ##

```
// multi-dimensional arrays are simply arrays of arrays
var a: Array<Array<int>> = [];
var b: Array<Array<int>> = [[0]];
// and can have different lengths (non-rectangular)
var c: Array<Array<int>> = [[0, 1], [2, 3, 4]];
// non-rectangular array with type inference
var d = [[0, 1], [2, 3, 4]];
```

## Reading and writing elements ##

Reading and writing elements of arrays uses the `[ ... ]` syntax like arrays in many other languages. The index expression into the array must be of an integer type (i.e. not specifically just `int`, any type `iN` or `uN`).

```
var a: Array<bool> = [true, false];
var x: bool = a[0];    // array element read
var y: bool = a[0uL];  // array element read of very large index
var z: int = a.length; // read of array length
```

```
def main() {
    var x = Array<int>.new(3);
    x[0] = 11; // assignment to array element
    var y = x[0];
}
```

## Bounds and null checks ##

Accesses of Virgil arrays are dynamically checked against the bounds. An access of a null array results in a `!NullCheckException` and using an index out of the range `[0, array.length)` will result in a `!BoundsCheckException`.

```
def main() {
var a: Array<int>;
    a[0] = 0; // produces !NullCheckException
}
```

```
def main() {
    var x = Array<int>.new(3);
    x[3] = 11; // produces !BoundsCheckException
    var y = x[0];
}
```

## Composability ##

Unlike most other languages, Virgil arrays can be constructed with _any_ element type, even `void`. There are no special cases or exceptions to remember. For any valid type `T`, `Array<T>` is also a valid type. This works with [primitives](Primitives.md), `void`, [tuples](Tuples.md), arrays, [classes](Classes.md), and [functions](Functions.md). No exceptions!

```
// if T is a legal type, then Array<T> is a legal type, even T=void
var a: Array<void> = [()];
var b: Array<void> = [(), (), ()];
var c: Array<void> = [];
```

Why is this useful? Composability makes the language regular so that you don't have to remember special cases. It means that arrays compose well with [functions](Functions.md) and [type parameters](Typeparams.md), as we will see later.

## Type inference ##

We've seen that we can omit the type declaration for most variable declarations, but we can also often omit the element type in an array creation if the element type can be inferred from the context.

```
// often the element type of an array creation can be inferred
var a: Array<int> = Array.new(3);
var b: Array<bool> = Array.new(7);
```

## Not co-variant ##

Unlike Java, Virgil arrays are _not_ co-variantly typed. See the section on [variance](Variance.md) for more details.
