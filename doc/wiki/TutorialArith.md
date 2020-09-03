# Arithmetic #

Arithmetic is fundamental to computation. Virgil defines a number of arithmetic operators on the primitive types. Thankfully, these arithmetic operators have well-defined, platform-independent semantics: for the same inputs, they always compute the same result on any platform. (This is not true for languages like C, C++, and Go).

## Integer types ##

Virgil offers signed integers `iN` and unsigned integers `uN` of every width from `1` to `64`. 

* `int` is an alias for the integer type `i32`
* `long` is an alias for the integer type `i64`
* `byte` is an alias for the integer type `u8`

All integers are represented in two's complement, and all arithmetic operations use two's complement. There are no platform-dependent integer types or integer operations. Therefore addition, subtraction, multiplication, division, and modulus "wrap-around" as they do on all modern CPUs. (This is quite unlike C and C++ which define neither the size of integers nor the result of overflowing basic operators).

```
// with declared type
var a: int = 9 + 3; // add == 12
var b: int = 8 - 2; // subtract == 6
var c: int = 7 * 4; // multiply == 28
var d: int = 9 / 2; // divide == 4
var e: int = 5 % 3; // modulus == 2
// with inferred type
var f = 9 + 3; // add == 12
var g = 8 - 2; // subtract == 6
var h = 7 * 4; // multiply == 28
var i = 9 / 2; // divide == 4
var j = 5 % 3; // modulus == 2
```


Bitwise and, or, and exclusive-or work as expected.

```
// with declared type
var a: int = 0xA0 >> 4; // shift right == 0x0A == 10
var b: int = 0x0F << 8; // shift left == 0xF00 == 3840
var c: int = 0b1001 & 1; // and == 0b001 == 1
var d: int = 0b1100 | 1; // or == 0b1101 == 13
var e: int = 0b1101 ^ 1; // xor == 0b1100 == 12
// with inferred type
var f = 0xA0 >> 4; // shift right == 0x0A == 10
var g = 0x0F << 8; // shift left == 0xF00 == 3840
var h = 0b1001 & 1; // and == 0b001 == 1
var i = 0b1100 | 1; // or == 0b1101 == 13
var j = 0b1101 ^ 1; // xor == 0b1100 == 12
```

Notice that Virgil allows writing integer constants in decimal, hexadecimal, and binary, but **not** in octal.

## Literals ##

Rules for integer literals are pretty simple.

* Decimal and hexadecimal literals are of type `int` by default.
* If a literal is too large to fit into the value range of `int`, it is of type `long`.
* The `l` or `L` suffix explicitly specifies the `long` type for a literal.
* The `u` or `U` suffix specifies _unsigned_, i.e. `u32` instead of `int` or `u64` instead of `long`.

An integer literal will be value-range checked and converted to the expected type if used in a context where a smaller integer type is expected.

```
// with declared type
var a: byte = 0xA0; // legal; 0xA0 fits in byte range
var b: i20 = 2L;   // legal; 2 fits into i20 range
def foo(x: byte) {
    foo(0);  // legal; 0 of type int implicitly converted to byte
}
```

## Shifts are different ##

In Virgil III, shifts on integers can be thought of as occurring in a window of bits that is exactly as wide as the type. For a integer type `iN`, where `N` is a width in bits, a shift amount of more than `N` will result in shifting out all of the bits (as opposed to other languages that either leave overshifts undefined, mask the shift amount, etc). Right shift `>>` is arithmetic (meaning, the sign bit is copied down) for signed integer types and logical (meaning, `0` bits are copied down) for unsigned types. The `>>>` operator performs logical right shifts on either signed or unsigned integers.

```
// a shift of < 0 or >= 32 bits always produces 0
var a: int =  1 << 33; // == 0; unlike Java == 2
var b: int =  1 << -1; // == 0  unlike Java == MININT
var c: int = -1 << -1; // == 0; unlike Java == MININT
var d: int =  3 >> 33; // == 0; unlike Java == 1
var e: int =  3 >> -1; // == 0
var f: int = -1 >> -1; // == 0; unlike Java == -1
```

