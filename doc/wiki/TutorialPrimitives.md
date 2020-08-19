# Primitives #

Virgil III offers a small set of primitive types that are useful for performing arithmetic and representing data.

## Booleans ##

With only two values, `true`, and `false`, booleans are represented in Virgil with the type `bool`. Here are some example uses of boolean variables, with and without type inference.

```

// with declared types
var x: bool; // default = false
var a: bool = true;
var b: bool = false;
// with type inference
var c = true;
var d = false;```

## Integers ##

Virgil supports a basic integer type, `int`, a _signed_ 32-bit value. Constants can be written in decimal, hexadecimal, or binary.

```

// with declared types
var d: int; // default == 0
var a: int = 0;
var b: int = 9993;
var c: int = -42;
// with type inference
var x = 0;
var y = 9993;
var z = -42;```

```

// with declared types
var a: int = 0b00;
var b: int = 0b1001;
var c: int = 0b111011100111;
var d: int = 0b11111111000000001111111100000000;
// with type inference
var x = 0b111011100111;
var y = 0b11111111000000001111111100000000;```

```

// with declared types
var a: int = 0x00;
var b: int = 0xAB07;
var c: int = 0xFFFFFFFF;
var d: int = 0xFEDCBA90;
var e: int = 0x01234567;
// with type inference
var x = 0xFEDCBA90;
var y = 0x01234567;```

The minimum decimal value is `-2147483648` (equal to `-2^31`) and the maximum value is `2147483647` (equal to `2^31 - 1`).

```

def MAX_VALUE: int = 2147483647;  // == 2^31 - 1
def MIN_VALUE: int = -2147483648; // == -2^31```

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
var h = '#';```

```

// with declared types
var x: byte; // default == 0
var a: byte = '\x00'; // == 0
var b: byte = '\x0A'; // == 10
var c: byte = '\xF1'; // == 241
var d: byte = '\xFF'; // == 255
// with type inference
var e = '\xF1'; // == 241
var f = '\xFF'; // == 255```

## Implicit byte promotion ##

Virgil automatically promotes `byte` values to `int` values where necessary, zero-extending them. This is the only implicit conversion that it supports.

## Void ##

Virgil also supports a `void` type that represents the return type of methods with no explicitly declared return type. As you will see later, there is nothing special at all about the `void` type; it can be used as the type of a variable, parameter, in an array, etc. The `void` type has just one value, `()`.

```

// void is just like other types
var x: void;
var a: void = (); // () is the only value of type void
var b = ();```

Because `void` is a type just like any other, it's perfectly legal to use it as the type of a variable, and it is perfectly acceptable to use the `()` value wherever a `void` value is expected, such as the return value from a `void` method.

```

var v: void = m(); // m() returns a void
def m() {
return (); // () is of type void
}```

Why would we want `void` to be a real type and have an actual value? We will see several examples later that show how this ability allows us to compose constructs in more natural ways. In particular, combining first-class functions and type parameters are a common use case where treating `void` as a real type is handy.

## Future compatibility ##

Currently there are no floating point types, nor 16-bit or 64-bit integer types. They will be added in a future version of Virgil.