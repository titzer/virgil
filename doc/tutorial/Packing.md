# Packing and Unpacking Integers

Systems programming often requires squeezing several small pieces of data into the bits of a single machine integer.
Instruction encodings, network headers, hardware registers, and compact in-memory data structures all do this.
Written by hand, that means a thicket of shifts, masks, and sign-extensions that is easy to get subtly wrong.

Virgil's `pack` and `unpack` operators do this for you.
Given a *layout described by a type*, the compiler computes the bit positions and generates the shifts and masks itself.

```
def rgb = u24.pack<(byte, byte, byte)>((0x12, 0x34, 0x56)); // == 0x123456
def c = u24.unpack<(byte, byte, byte)>(rgb);                // == (0x12, 0x34, 0x56)
def green = c.1;                                            // == 0x34
```

## The two operators

Both operators are members of an *integer* type, which acts as the container for the bits.

  * `iN.pack<T>` has type `T -> iN`. It flattens a value of type `T` into the bits of `iN`.
  * `iN.unpack<T>` has type `iN -> T`. It is the inverse, rebuilding a `T` from the bits.

The type argument `T` describes the layout.
Every type that can be packed has a statically-known *packing width*, and the operators are only well-typed when that width fits in `N` bits.

## Bit layout: first field occupies the high bits

Fields are laid out in declaration order, **left to right, from the most significant bit down**.
This is the order you would write the value on paper, so a packed hexadecimal constant reads the same as the tuple that produced it.

```
var x = u16.pack<(u4, u4, u4, u4)>((0xA, 0xB, 0xC, 0xD)); // == 0xABCD
```

Each field occupies exactly as many bits as its own type is wide, with no padding between fields.
So the layout above is:

```
   bit  15 .. 12   11 .. 8    7 .. 4     3 .. 0
        [  0xA  ] [  0xB  ] [  0xC  ] [  0xD  ]
```

If the container type is wider than the total packing width, the value is placed in the **low** bits and the unused high bits are zero.

```
var y = u16.pack<(u4, u4)>((0xA, 0xB)); // == 0x00AB, not 0xAB00
```

Correspondingly, `unpack` ignores any bits above the packing width, rather than rejecting them.

```
var z = u16.unpack<(u4, u4)>(0xFFAB); // == (0xA, 0xB); the 0xFF is discarded
```

## What can be packed

| Type                    | Packing width                          |
|-------------------------|----------------------------------------|
| `iN`, `uN`              | `N` bits                               |
| `bool`                  | 1 bit                                  |
| `float`                 | 32 bits (raw IEEE 754 bit pattern)     |
| `double`                | 64 bits (raw IEEE 754 bit pattern)     |
| an `enum` with `M` cases | enough bits to hold the largest tag    |
| an `enum`'s `.set` type  | one bit per enum case                  |
| a tuple                 | the sum of its elements' widths        |
| a data type             | the sum of its fields' widths          |

Tuples may be nested; nesting is purely notational and does not affect the layout, because the fields are flattened in order.

```
var a = u12.pack<(u4, (u4, u4))>((0xA, (0xB, 0xC))); // == 0xABC
```

## Signed fields

A signed field is stored as two's complement within its own width, and `unpack` sign-extends it back out.
This means signed fields round-trip correctly even though they occupy only a few bits.

```
var p = u8.pack<(i4, i4)>((-3, 5));   // == 0xD5; -3 is 0b1101 in 4 bits
var q = u8.unpack<(i4, i4)>(0xD5);    // == (-3, 5)
```

The container type's own signedness only affects how you read the *result*; the bits are the same.

```
var r = i8.pack<(u4, u4)>((0xF, 0xF)); // == -1, because 0xFF viewed as i8 is -1
```

## Floating point

Packing a `float` or `double` yields its raw IEEE 754 bit pattern, the same value you would get from `u32.view` or `u64.view`.
Since these are exact bit patterns, they round-trip.

```
var bits = u32.pack<float>(1.5f);        // == 0x3FC00000
var back = u32.unpack<float>(bits);      // == 1.5f
```

## Enums and enum sets

An `enum` packs to its tag, using only as many bits as the largest tag requires.
An enum `.set` packs to its bitset representation, one bit per case, which is exactly the representation Virgil already uses.

```
enum E { A, B, C, D }

var t = u2.pack<E>(E.D);            // == 3, the tag of E.D
var s = u4.pack<E.set>(E.B | E.D);  // == 0b1010
```

An enum with 5 cases needs 3 bits, so `u2.pack<E>` would be a compile-time error for that enum.

## Data types

A data type -- a `type` declared with fields but no `case`s -- packs as though its fields were a tuple, in declaration order.
This is often more readable than a bare tuple, because the fields have names.

```
type Rgb(r: byte, g: byte, b: byte) { }

var c = u24.pack<Rgb>(Rgb(0x12, 0x34, 0x56)); // == 0x123456
var d = u24.unpack<Rgb>(c);                   // Rgb(0x12, 0x34, 0x56)
var e = d.g;                                  // == 0x34
```

Data types compose with tuples, so larger encodings can be built from named pieces.

```
var f = u32.pack<(bool, Rgb)>((true, Rgb(0xAA, 0xBB, 0xCC))); // == 0x1AABBCC
```

## Errors are caught at compile time

Because the packing width is statically known, a layout that does not fit is a type error, not a runtime failure.
There is no `pack` equivalent of a value-range check: the *type* either fits or it doesn't.

```
var a = u4.pack<(u4, u4)>((1, 2));
// TypeError: u4.pack cannot represent values of type (u4, u4), which require 8 bits
```

Types with no fixed bit width are rejected as well.

```
class C { }
var b = u32.pack<C>(C.new());
// TypeError: u32.pack cannot represent values of type C, because C is a class

var c = u32.pack<Array<byte>>([1]);
// TypeError: u32.pack cannot represent values of type Array<byte>, because Array<byte> is not a primitive type
```

## Use as first-class functions

Like other Virgil operators, `pack` and `unpack` are first-class values.
They are polymorphic, so as a value they need their type argument written explicitly.

```
def encode = u16.pack<(u4, u4)>;   // of type (u4, u4) -> u16
var x = encode((0xA, 0xB));        // == 0x00AB
```

In a call, the type argument of `unpack` can usually be inferred from the context that consumes the result.

```
var t: (u4, u4) = u16.unpack(0xAB); // type argument inferred as (u4, u4)
```

For `pack`, the type argument is generally worth writing out.
Integer literals default to `int`, so `u16.pack((0xA, 0xB))` infers `(int, int)` -- which is 64 bits wide and does not fit -- rather than the narrow types you meant.

## Limitation: variants with cases

Packing is currently supported only for the types listed above.
A variant declared with `case`s -- as opposed to a data type with no cases -- is **not** supported, because the layout does not reserve any bits for the case tag.

```
type T { case A(x: u4); case B(y: u4); }
var bad = u8.pack<T>(T.B(3));  // does not work
```

Unfortunately this is not currently rejected by the type checker; see `doc/aeneas-issues.txt`.
Until it is fixed, pack only data types (`type P(...) { }`), tuples, and the primitive types above.
If you need to encode a tagged union by hand, pack the tag and the payload as separate tuple elements.
