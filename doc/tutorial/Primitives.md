# Primitives #

Virgil III offers a small set of primitive types that are useful for performing arithmetic and representing data.

## Booleans ##

With only two values, `true`, and `false`, booleans are represented in Virgil with the type `bool`.
Here are some example uses of boolean variables, with and without type inference.

```
// with declared types
var x: bool; // default = false
var a: bool = true;
var b: bool = false;
// with type inference
var c = true;
var d = false;
```

## Integers ##

Virgil supports fixed-width signed and unsigned integer types of size 1 to 64 bits.
The most common is the `int` type, a _signed_ 32-bit value. Constants can be written in decimal, hexadecimal, or binary.

```
// with declared types
var d: int; // default == 0
var a: int = 0;
var b: int = 9993;
var c: int = -42;
// with type inference
var x = 0;
var y = 9993;
var z = -42;
```

```
// with declared types
var a: int = 0b00;
var b: int = 0b1001;
var c: int = 0b111011100111;
var d: int = 0b11111111000000001111111100000000;
// with type inference
var x = 0b111011100111;
var y = 0b11111111000000001111111100000000;
```

```
// with declared types
var a: int = 0x00;
var b: int = 0xAB07;
var c: int = 0xFFFFFFFF;
var d: int = 0xFEDCBA90;
var e: int = 0x01234567;
// with type inference
var x = 0xFEDCBA90;
var y = 0x01234567;
```

The minimum decimal value for type `int` is `-2147483648` (equal to `-2^31`) and the maximum value is `2147483647` (equal to `2^31 - 1`). These values are accessible as the members `max` and `min` of type `int`.

```
def INT_MAX_VALUE = int.max;  // == 2147483647
def INT_MIN_VALUE = int.min; // == -2147483648
```

## Long ##

The `long` type is a signed, 64-bit integer type. It extends the range of integers and is the default type of literals that do not fit in the range of `int`. A  suffix of `l` or `L` can be supplied to specify that a numeric literal is of type `long` rather than the default of `int`.

```
// with declared types
var a: long = 0x00;
var b: long = 0xAB07;
var c: long = 0xFFFFFFFF;
var d: long = 0x11223344FEDCBA90;
var e: long = 987823748783;
// with type inference
var x = 0x99887766FEDCBA90;
var y = 0xFFFFFFFF01234567;
```

## Bytes ##

Virgil supports _unsigned_ 8-bit integers with the `byte` type. Byte literals can be written in hexadecimal in single quotes or as ASCII characters.

```
// with declared types
var x: byte; // default == '\x00'
var a: byte = 'a';
var b: byte = 'b';
var c: byte = '0';
var d: byte = ' ';
var e: byte = '\n';
var f: byte = '\t';
// with type inference
var g = '$';
var h = '#';
```

```
// with declared types
var x: byte; // default == 0
var a: byte = '\x00'; // == 0
var b: byte = '\x0A'; // == 10
var c: byte = '\xF1'; // == 241
var d: byte = '\xFF'; // == 255
// with type inference
var e = '\xF1'; // == 241
var f = '\xFF'; // == 255
```

## Implicit integer promotion ##

Virgil automatically promotes smaller-width integer values to larger-width integer values when necessary.
Such a promotion does not change the _value_ of an integer, just its representation.
For more information on how numbers relate to their representations, see [here](Numbers.md).
The most common example is extending `byte` values to `int` values where necessary, zero-extending them. 


## Void ##

Virgil also supports a `void` type that represents the return type of methods with no explicitly declared return type. As you will see later, there is nothing special at all about the `void` type; it can be used as the type of a variable, parameter, in an array, etc. The `void` type has just one value, `()`.

```
// void is just like other types
var x: void;
var a: void = (); // () is the only value of type void
var b = ();
```

Because `void` is a type just like any other, it's perfectly legal to use it as the type of a variable, and it is perfectly acceptable to use the `()` value wherever a `void` value is expected, such as the return value from a `void` method.

```
var v: void = m(); // m() returns a void
def m() {
return (); // () is of type void
}
```

Why would we want `void` to be a real type and have an actual value? We will see several examples later that show how this ability allows us to compose constructs in more natural ways. In particular, combining first-class functions and type parameters are a common use case where treating `void` as a real type is handy.

## Floating point ##

Virgil supports single-precision (32-bit) and double-precision (64-bit) floating point numbers that conform the the IEEE 754 specification for floating point.

```
// float is a single-precision 32-bit floating point value 
var x: float;
var y: float = 0.0;
var z: float = 1f; // the 'f' suffix specifies single-precision
```

```
// double is a double-precision 64-bit floating point value 
var x: double;
var y: double = 0.0;
var z: double = 5d;  // the 'd' suffix specifies double precision
```

