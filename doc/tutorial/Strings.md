# Strings #

Virgil III has very basic support for strings; they are represented as mutable arrays of bytes. String literals are translated into arrays of bytes and usable as arrays of bytes in your program. In fact, the `string` type is just an alias for `Array<byte>`. The two types are completely interchangeable.

```
var a: string = "";
var b: string = "The quick brown fox";
var c: string = null;
```

## Escapes ##

Strings can use the '\\' character to escape some characters, such as carriage return, newline, tab, and quotes within strings.

```
// newline, tab, carriage-return, backslash, single-quote and double-quote
var a: string = "\n\t\r\\\'\"";
```

## Hex byte values ##

Strings can use embedded hexadecimal byte values escaped with `\xXX`.

```
// hexadecimal bytes can be used in string literals
var a: string = "\x00\x0A\xF1\xDD\xFF";
```

## Strings are arrays ##

Remember that strings are simply arrays of bytes. The individual bytes can be accessed just as a normal byte array, as can the length. Out of bounds accesses cause exceptions as well.

```
var a: string = "abcvar";
var b: byte = a[0]; // strings are just arrays of bytes
```

```
def main() {
    var a = "abcvar";
    var x = a[11]; // produces !BoundsCheckException
}
```

## Forward compatibility ##

This is not the final design for strings. In the future, Virgil III will support _immutable_ arrays, and the `string` type will be an alias for an _immutable_ array of bytes. Generally speaking, it's a bad idea to modify the contents of a string. Don't do it!
