# Numbers #

Numbers in Virgil are represented by two main kinds of types: fixed-size integers and floating point.
Both are efficient value types, i.e. the compiler will represent them as corresponding machine-level types without boxing.
Virgil is unique in that the rules for integer types and floating point types prevent several common sources of confusion and bugs, particularly around rounding and conversions.
In particular, Virgil strives to preserve the meaning of numbers across representation changes to avoid subtle bugs.

## Fixed-size Integer types

As covered [here](FixedSizeIntegers.md), fixed-size integer types are either signed or unsigned and have arbitrary width between `1` and `64` bits.
Integer types are always independent of the target machine's bit-width.
Operations on integer values include the typical set of addition, subtraction, multiplication, division, modulus, shifts, bitwise operations, and comparisons.
They too, always work the same on all compilation targets.

Integer literals can be written in decimal, hexadecimal, or binary format and can have explicit width as a suffix.
Importantly, fixed-size integer types are only implicitly promoted (e.g. a smaller-width integer extended to be usable as a larger-width integer) when promotion doesn't change the meaning of its value.
All other conversions require either casts (the `!` operator), rounding, or a bitwise `view` operation.
This preserves the "numeric" qualities of an integer: any comparison (equality, less-than, greater-than, etc) between integers works the same way, independent of the integer width.
That's important for two reasons: 1) a promotion can always be _undone_, recovering the same original value, and 2) comparisons between numbers in _different representations_ still works as expected.

## Floating Point types

Floating point numbers in Virgil follow the accepted IEEE 754 standard for floating point representation and operations.
Virgil supports both single-precision (32 bit) and double-precision (64 bit) numbers.
Modulo the typical looseness in the IEEE 754 specification around the bit patterns of NaN values, Virgil floats work independent of hardware.

```
var x: float = 1.0f;
var d: double = 1.0;
```

## Implicit Promotions

To avoid confusion between number representations and subtle bugs that can arise in automatic conversions between numeric types, Virgil only implicitly promotes number types when such a promotion is guaranteed to never change a value or lose information.
For example, the rules for promotions between fixed-size integer types (basically, smaller types can be auto-promoted to larger types, depending on sign) allow for efficient implementation but also that no bits, particularly the sign bit, are ever lost.
Promotion from single-precision `float` to double-precision `double` is similar; no information is lost.
The same holds true for integer to float conversions: integer values are only promoted to floating point values when it is possible to do so without rounding.

```
var x: float = 11f;
var y: double = x;   // OK: implicit promotion

var i: int = 33;
var f: float = i;    // Not OK: 32-bit integers need to be rounded to fit into 32-bit float
var d: double = i;   // OK: 32-bit integers can fit into 64-bit double without rounding
```

## Explicit Casts: `T.!`

Casts between numeric types in Virgil are designed to always preserve the underlying numeric value, and only change its representation.
For example, a cast of the number `5` represented as an `int` to the target type `u32` should succeed and preserve `5` as the result value.
Yet the number `-5` represented as `int` cannot be represented as any unsigned value; all such cases will dynamically fail.
Because of this, these casts can sometimes fail, which is unlike most languages that perform representation conversion instead.
Thus the rule is: when a cast between numeric types encounters a value that _cannot be encoded exactly_ in the destination type, the cast fails.
This holds true for casts between signed and unsigned integers (per example) and between floating point numbers and integers (e.g. a floating point value must be rounded to the nearest integer).

```
var f1 = 1.0f;
var f2 = 2.1f;

var x: int = int.!(f1);   // success, rounded value is exact
var y: int = int.!(f2);   // fail, rounded value is different

var i: int = 200000000;
var f3 = float.!(i);      // fail, rounded value is different
```

## Rounding and Truncation

Conversion between floating point and integer types with rounding and truncation are possible.
They exist as named operations to make their use more clear (rather than special symbols).
Truncation of a floating point number to an integer discards the fractional part and clamps values too large or too small to be represented to either `iN.min` or `iN.max`.
Rounding of an integer to a floating point number makes use of the default rounding mode, (round to nearest, ties to even).
Rounding a double to a float (i.e. demotion) is explicit and makes similar use of the rounding mode.

```
var f: float = 2.1f;
var z: int = int.truncf(f);   // truncation: result is 1

var g: float = float.roundi(2_000_000_001);  // rounding: performs round-to-nearest, result is 2e9

var h: double = 22.009;
var j: float = float.roundd(h);  // rounding: performs round-to-nearest demotion
```

## Bitwise Reinterpretations: `T.view`

In processing low-level data, it is common to "inspect the bits" of a value, e.g. to treat a 32-bit signed integer as a 32-bit unsigned integer to write it to disk or a stream, or to load binary floating point numbers from disk.
For this purpose, primitive numeric types have appropriate `view` operations that accept inputs of other numeric types with the same bit-width.

```
var x: i32 = 88;
var y: u32 = u32.view(x);       // reinterpret signed bits as unsigned

var f: float = float.view(y);   // reinterpret int bits as float
var g: int = int.view(f);       // reinterpret float bits as int

var m: long = -99999L;
var n: double = double.view(m); // reinterpret long bits as double
```

## Comparisons across representations

Virgil's rules for numbers ensure that comparisons of numbers with different signs, or even comparing floating point numbers and integers, always works as expected.
For example, if we compare an integer with a floating point number, then the integer _will not be rounded improperly_.
Rounding in comparisons must use the proper rounding direction, depending on the comparison.
For now, Virgil is conservative by requiring promotion of the integer (which fails type checking if not possible).
In the future, it is possible to relax the restrictions and have the compiler insert the correct rounding(s).

```
var x: int = -22;
var y: u32 = 22;
var z = if(x < y, "correct", "incorrect");  // true; mixed-sign comparison handled properly without promotion

var f: float = -22.1f;
var w = if(x > f, "correct", "incorrect");  // should be true; currently a type error because promotion not possible.
```
