# String Utilities

The `Strings` component provides a set of utility methods designed for string manipulation, including functions for hashing, comparing, and other common operations.

## Methods Overview

### Whitespace Handling
- **isWhiteSpace(c: byte) -> bool**
  - Returns `true` if the character `c` is considered whitespace (`' '`, `'\t'`, `'\r'`, or `'\n'`).
- **strip(str: string) -> string**
  - Removes all leading and trailing whitespace characters from `str`.

### String Comparison
- **startsWith(str: string, start: string) -> bool**
  - Checks if `str` starts with the substring `start`.
- **endsWith(str: string, end: string) -> bool**
  - Checks if `str` ends with the substring `end`.
- **endsWithFrom(str: string, start: int, end: string) -> bool**
  - Checks if `str` ends with `end` after skipping `start` characters.

### Hashing and Equality
- **hash(str: string) -> int**
  - Computes a hash code for `str`.
- **equal(arr1: string, arr2: string) -> bool**
  - Compares two strings for equality.

### String Building and Formatting
- **newMap<V>() -> HashMap<string, V>**
  - Creates a new HashMap with strings as keys, using `hash` and `equal` for hashing and comparison.
- **renderDecimal(buf: Array<byte>, pos: int, val: int) -> int**
  - Renders an integer `val` as a decimal into the buffer `buf` starting at position `pos`.
- **renderHex8(buf: Array<byte>, pos: int, val: int) -> int**
  - Renders an integer `val` as hexadecimal into the buffer `buf` starting at position `pos`.
- **render(render: StringBuilder -> StringBuilder) -> string**
  - Produces a string from a `render` function that renders into a `StringBuilder`.
- **builderOf(str: string) -> StringBuilder**
  - Allocates a new string buffer and copies `str` into it.
- **format1\<A\>(fmt: string, a: A) -> string**
  - Renders the format string `fmt` with the parameter `a` into a string.
- **format2\<A, B\>(fmt: string, a: A, b: B) -> string**
  - Renders the format string `fmt` with parameters `a` and `b` into a string.
- **format3\<A, B, C\>(fmt: string, a: A, b: B, c: C) -> string**
  - Renders the format string `fmt` with parameters `a`, `b`, and `c` into a string.

### Parsing and Utilities
- **parseLiteral(a: Array<byte>, pos: int) -> (int, string)**
  - Parses a double-quoted string constant starting at position `pos` in array `a`.
- **puts(s: string) -> StringBuilder -> StringBuilder**
  - Returns a closure that appends string `s` to a `StringBuilder`.
- **asciiLt(a: string, b: string) -> bool**
  - Compares two strings according to 8-bit ASCII lexicographical order.
- **nonnull(s: string) -> string**
  - Returns the input string `s` if it is not null, or "<null>" if `s` is null.

This component enhances string handling capabilities in applications, providing robust tools for common string operations required in many programming tasks.
