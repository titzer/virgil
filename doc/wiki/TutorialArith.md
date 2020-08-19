# Arithmetic #

Arithmetic is fundamental to computation. Virgil defines a number of arithmetic operators on the primitive types. Thankfully, these arithmetic operators have well-defined, platform-independent semantics: for the same inputs, they always compute the same result on any platform. (This is not true for languages like C, C++, and Go).

## Signed, two's complement `int` ##

Values of type `int` are always represented in 32-bit two's complement. Addition, subtraction, multiplication, division, and modulus "wrap-around" as they do in Java. (This is quite unlike C and C++ which define neither the size of integers nor the result of overflowing basic operators).

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
var j = 5 % 3; // modulus == 2```


Bitwise and, or, and exclusive-or work as expected.

```

// with declared type
var a: int = 0xA0 #>> 4; // shift right == 0x0A == 10
var b: int = 0x0F #<< 8; // shift left == 0xF00 == 3840
var c: int = 0b1001 & 1; // and == 0b001 == 1
var d: int = 0b1100 | 1; // or == 0b1101 == 13
var e: int = 0b1101 ^ 1; // xor == 0b1100 == 12
// with inferred type
var f = 0xA0 #>> 4; // shift right == 0x0A == 10
var g = 0x0F #<< 8; // shift left == 0xF00 == 3840
var h = 0b1001 & 1; // and == 0b001 == 1
var i = 0b1100 | 1; // or == 0b1101 == 13
var j = 0b1101 ^ 1; // xor == 0b1100 == 12```

Notice that Virgil allows writing integer constants in decimal, hexadecimal, and binary, but **not** in octal.

## Shifts are different ##

In Virgil III, shifts are always logical, meaning that right shifts do not preserve the sign bit. The `#<<` and `#>>` operators represent shift left and shift right.

```

// a shift of < 0 or >= 32 bits always produces 0
var a: int =  1 #<< 33; // == 0; unlike Java == 2
var b: int =  1 #<< -1; // == 0  unlike Java == MININT
var c: int = -1 #<< -1; // == 0; unlike Java == MININT
var d: int =  3 #>> 33; // == 0; unlike Java == 1
var e: int =  3 #>> -1; // == 0
var f: int = -1 #>> -1; // == 0; unlike Java == -1```

Unlike Java, shifts by 32 or more bits in either direction always produce `0`, as do shifts by negative numbers.