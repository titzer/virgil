# `StringBuilder`

The `StringBuilder` class in Virgil is designed to facilitate efficient string construction and manipulation.

## Overview

`StringBuilder` helps in building strings by appending different data types (e.g., integers, booleans, arrays) to an internal buffer, which can then be converted to a string or used in various output methods.

## Core Features

### Instantiation
```virgil
var b = StringBuilder.new();
```

### Appending Data
- `.puts(string)` - Appends a string.
- `.putc(char)` - Appends a single character.
- `.putd(decimal)`, `.putx(hexadecimal)`, and `.putz(boolean)` - Used for appending numeric and boolean data in various formats.

### Output and Reset
- `.toString()` - Returns the current string value of the buffer and deletes the StringBuilder instance
- `.reset()` - Clears the buffer for reuse.
- `.grow(size)` - Suggests a new capacity for the buffer to optimize performance.

### Advanced Data Handling
- `.putk("substring", start, end)` - Adds a substring from `{start}` to `{end}`.
- `.putr(Range<byte>)` - Adds a range of bytes.
- `.pad(char, length)` - Pads the buffer with a character up to a specified length.

### Utility Functions
- `.ln()` - Appends a newline.
- `.tab()` - Adds a tab.

### Method Chaining
By returning `this` from most methods, `StringBuilder` allows chaining of method calls to streamline string building:
```virgil
b.puts("Hello").sp().puts("Again...").ln();
```

### Formatting
Supports format strings for simplifying complex string constructions:
- `%d` for integers.
- `%c` for characters.
- `%x` for hexadecimal numbers.
- `%s` for strings.
- `%z` for booleans.
- `%q` for custom callback functions that manipulate the `StringBuilder`.

Usage:
- `put1(fmt: string, p1: T1)` - Format a string, rendering `(1)` argument according to `{fmt}`.
- `put2(fmt: string, p1: T1, p2: T2)` - Format a string, rendering `(2)` argument according to `{fmt}`.
- `put3(fmt: string, p1: T1, p2: T2, p3: T3)` - Format a string, rendering `(3)` argument according to `{fmt}`.

## Example Usage in Practice
```virgil
def demo() {
    var b = StringBuilder.new();
    b.puts("Hello ").puts("World").putc('\n');
    var s = b.toString();
    System.puts(s);

    b.puts("Hello for the ").putd(33).puts("rd time.\n");
    System.puts(b.toString());
    
    b.reset();
    b.grow(124);
    b.pad('x', 20).ln();
    var out = StringBuilder.out(_, System.fileWriteK(1, _, _, _));

    b.put1("int = %d, ", (44 + 55));
    out(b.ln()).reset();
}
```


## Conclusion
`StringBuilder` in Virgil provides a robust, flexible way to build and manage strings efficiently, making it suitable for applications requiring dynamic string manipulation. The ability to chain methods and use format strings further enhances its utility, reducing code complexity and improving readability.
