# Fixed-size Integer Types

Many systems programming tasks require interacting with hardware, system calls, or other software that use integers smaller than typical machine word sizes.
Other times, using small integers rather than full word-sized integers can save a tremendous amount of program memory.

Virgil III supports a rich set of primitive integer types that allow efficient, portable, low-level programming while remaining easy to reason about.
This family of integer types is known as "fixed-size" or "fixed-width" integers because they represent integer values with a known bit-width and sign.
Because they cannot grow arbitrarily large, Virgil integer types are efficient and never allocate memory.
They are portable, too; Virgil integer types always behave exactly the same way, regardless of the compilation target, with no platform-specific pitfalls.

## Signed and unsigned integers up to `N` bits

While most CPUs today have 8, 16, 32, or 64 bits word sizes and arithmetic, Virgil provides integer types for all bit-widths from `1` to `64`.
The syntax for writing these types is:

 * `iN` for `N` in `1` ... `64` : signed integer types of `N` bits wide
 * `uN` for `N` in `1` ... `64` : unsigned integer types of `N` bits wide

These are *primitive* types in Virgil; they'll never be boxed into heap-allocated values.
That means that when compiling for a target with a smaller word size than the integer types in use, the Virgil compiler will transparently use multiple machine words to represent values of the type.

```
var x: i8 = 23;    // signed 8-bit integer == 23
var y: u9 = 44;    // unsigned 9-bit integer == 44
var z: Array<i43>; // array of signed 43-bit integers
```

## Common names for the most common integer types

While the full generality of Virgil's integer types is indispensible for some tasks, most programs use only a few common integer types.
To make these programs easier to read and write, and to make Virgil code look and behave more like very popular languages, the following are type aliases:

 * `int` = `i32` : the most commonly used integer type, signed 32-bit
 * `byte` = `u8` : unsigned byte; `Array<byte>` is typically used for low-level I/O
 * `long` = `i64` : the most common large integer type, signed 64-bit
 * `short` = `i16` : a common small integer size, signed 16-bit

```
var x: byte = 88;
var y: Array<byte> = [x, 77, 33];
var z: (int, long) = 33, -9999999999999;
```

## Two's complement and value ranges

All signed integer types in Virgil use what is known as "two's complement" representation, which is standard on nearly all computer hardware and in many other programming languages.
This means that every integer type has a value range easily determinable from its bit-width:

  * `iN` : value range from `-2^(n-1)` to `2^(n-1)-1`, inclusive
  * `uN` : value range from `0` to `2^(n)-1`, inclusive

Moreover, every integer type has two helpful member constants for the minimum and maximum value.

```
var a = i9.min;   // == -256
var b = i9.max;   // == 255
var c = u33.min;  // == 0
var d = u33.max;  // == 2^33 - 1
```

## Arithmetic "within a window"

Virgil fixed-size integer types support arithmetic that behaves as if performed on a machine with a wordsize of matching bit-width.
For example, if we have a signed `N`-bit integer type `iN`, then all arithmetic on values of type `iN` produces values of type `iN` and uses wrap-around rules consistent with two's complement arithmetic for size `N`.
It's no different for unsigned types.
This includes left shifts and both signed and unsigned right shifts; they all appear to happen within a window corresponding to the bit-width of the type.

For types and arithmetic that exactly match the target architecture, this induces no overhead, so 32-bit integer arithmetic and 64-bit arithmetic are typically zero-overhead on most targets.
For odd sizes, e.g. `i21`, the Virgil compiler will generate code that performs arithmetic in the available machine word size(s) and then insert (21-bit) sign-extensions where necessary to ensure extraneous upper bits in the machine representation are not observed.
This amounts to at most one zero- or sign- extend operation per source-level operation.
Often, the compiler can optimize away this overhead when it can be sure upper bits aren't observed.

## Promotion

In Virgil, integer types can be implicitly promoted whenever such a promotion does not lose information.
This essentially means that a narrower type (`iN` or `uN`) can be promoted to a wider type (`iW` or `uW`) when the wider type can represent all of narrower type's values.
That leads to the following straightforward rules:

 * `iN` is promotable to `iW` when `N` is less than or equal to `W`
 * `uN` is promotable to `uW` when `N` is less than or equal to `W`
 * `uN` is promotable to `iW` when `N` is less than `W`

Note above that an unsigned type *can* be promoted to a *larger* signed type, since that larger type can represent all of the smaller type's values.
However, a signed type is *never* promotable to an unsigned type, because negative values cannot be represented in an unsigned type.
Instead, to convert a signed integer type to an unsigned integer type, it must be `cast`ed or `view`ed, explained below.

## Integer literals

Virgil supports decimal, hexadecimal, and binary integer literals that can have an optional unsigned (`u` or `U`) or long (`l` or `L`) suffix.
Because Virgil also has local type inference, the type of a literal assigned in an initialization expression is important, since it will become the type of that variable.
What type does an integer literal have?
The rules are:

  * Integer literals without a suffix have a type `int`, regardless of sign.
  * Integer literals with a suffix of `u` or `U` are unsigned.
  * Integer literals with a suffix of `l` or `L` are 64 bits. They are signed unless they also have the `u` or `U` suffix.
  * Integer literals used in a context requiring a narrower type are *value range checked* at compile time and given the narrower type.

This means that despite the generality of Virgil's integer type system, the `int`, `u32`, `long` and `u64` types are special, as they are the inferred types for integer literals in the program.

```
var x = 1;         // decimal, type int
var y = 0x3Fu;     // hexadecimal, type u32
var z = 0b010101L; // binary, type long
var w = 8888uL;    // decimal type u64
```

After much experience, however, it turns out always inferring either 32-bit or 64-bit types for literals is inconvenient.
The last rule remedies this.
It is very common to write an integer literal in a context where a narrow integer type (like `byte`) is expected.
In that case, the Virgil compiler will test the *value* of the literal and if it is representable in the expected type, the literal will be given that type (and representation).

```
var a: byte = 88;  // ok; 88 fits in byte
var b: byte = 288; // error; 288 out of byte range
var c: u32 = -999; // error; -999 not representable in unsigned type
```

## Comparison on mixed types

While promotion and type inference have straightforward rules for a single literal or expression, and arithmetic on matching types uses the straightforward "two's complement in a window" rules, Virgil allows expressions with mixed integer types.
Their rules are a little more complicated, but still strive to be intuitive.

Comparisons on integer types always compare *integer values on the same number line*, regardless of the bit-width or signedness of the involved types.
For example, when comparing two expressions of opposite signs, it should never been the case that a negative value of the signed type is equal to a positive value of the unsigned type, even if the underlying bit patterns are identical.
This reasoning extends to inequalities such as `<` (less than), etc.

```
var x: int = 0x80000000;
var y: u32 = 0x80000000u;
var z1 = (x == y); // false, x is negative
var z2 = (x < y);  // true, -2147483648 < 2147483647
```

Intuitively, all integer comparisons are performed by first promoting both sides to a common wider type.
In practice, the Virgil compiler eliminates promotions when possible.
Mixed-sign comparisons are typically performed by first checking if the signed value is negative, in which case the comparison outcome is known, and if non-negative, performing an unsigned comparison.

## Arithmetic on mixed types

We've now seen that comparison of mixed integer types is intuitive; all integers are put on the same number line before being compared.
However, arithmetic with mixed integer types is less intuitive.

In Virgil, syntactic infix operators like `+` and `-` are *overloaded*; they mean different things depending on the input types.
For integer types, if both sides of the operator are of the same type, then we get "two's complement in a window" on that type.

However, if the sides differ, it is not clear what is the best way of resolving an overloaded infix operator.
If the type of the left hand side is `L` and the right-hand side is `R`, there are several possible rules.
They can get quite complicated!
For now, Virgil chooses a simple one:

  * Use type `L` to resolve infix operators (`+` `-` `/` `*` `%` `&` `|` `^` `<<` `>>` `>>>`)
  * Let the normal promotion rules for `R` to `L` handle the right hand side

This rule means that some expressions need manual promotions (casts) or they will be errors.
Redundant casts will optimized away by the compiler; they serve only as static type hint.

```
var x: byte;
var y: u32;

var z1 = x + y;         // error: byte + u32, u32 not promotable to byte
var z2 = y + x;         // ok; u32 + byte, byte is implicitly promoted to u32
var z3 = u32.!(x) + y;  // ok; u32 + u32, manual promotion
```

## Casting and viewing

Promotions to wider integer types are easy to understand; they never alter integer values, just make their representation larger.
However, the reverse operation, converting values of a wider integer type to a narrow integer type, are not so simple.
The reverse operation must handle values that are not representable in the narrower type.

Virgil has two operations to convert a possibly wider and/or opposite sign integer type to a narrower integer type.

  * An integer `cast` operation from type `iW` to `iN` performs a value range check and throws an exception for integer values in `iW` that are not representable in `iN`.
  * An integer `view` operation from type `iW` to `iN` reinterprets the lower `N` bits of the integer value as type `iN`.

Both operations are available for all pairs of integer types, including mixed signs.
For promotable types, these operations are both equivalent and behave the same as implicit promotions.

Casts and views are available as members on the *target* type.

```
var x = i8.view(87384); // reinterpret lower 8 bits as signed integer type i8
var y = i8.cast(87384); // exception; value range check will fail
```

Like most other operators in Virgil, the `cast` and `view` operations can be used as first-class functions.
However, they each have a type parameter which represents the type of their argument, so, like other polymorphic functions, they need a type argument when used as a first-class value.
Virgil enforces that this type argument must be an integral type.
As always, the compiler will infer type arguments when possible.

```
var x = byte.view<int>;          // of type int -> byte
var y: int -> byte = byte.cast;  // type argument inferred
```

## Legacy casts and the `!` operator

Before 2020, Virgil had only the integer `view` operation (though not named as such), and the syntactic cast operation `!` mapped to this operation.
However, this operation is not the best default for most situations, since it silently converts negative integers to (large) positive integers, which is often a logical bug.
Instead, the `view` and `cast` operations were introduced.

```
var x = byte.!(-999); // == byte.view or byte.cast?
```

For now, the syntactic cast operator `!` still maps to `view`, but a compiler switch exists to change its meaning to the `cast` operation.
This represents a change to Virgil's language semantics and therefore changes the meaning of some programs.
Since the compiler, runtime, and lots of tests are written in Virgil, a migration is underway.
When the migration is complete, this compiler flag will be flipped in an upcoming release and `cast` will be the default in the future.

Programs that explicitly use either `view` or `cast` will not change meaning.
It is recommended to use the explicit operations when brevity is not paramount.

## A wider future

It is occasionally useful to work with integer types larger than `64`.
While this can be done by application code using tuples, arrays, or even vectors of fixed-size integers, implementing all relevant arithmetic to achieve general-purpose wide integers is a tedious task.
The Virgil compiler already does most of this internally!
In the future, Virgil may offer even larger, or even unbounded- (but still fixed-) width integers by lifting the syntactic limit on `N`.
