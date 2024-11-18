# Integer and Long Integer Utilities

These utilities offer methods for parsing and rendering integers (`Ints` component) and long integers (`Longs` component) in various formats, and include additional arithmetic routines.

## Ints Component

### Methods Overview

#### Decimal Parsing
- **parseDecimal(a: Array<byte>, pos: int) -> (int, int)**
  - Parses a decimal integer from `a` starting at `pos`. Handles negative values.
- **parsePosDecimal(a: Array<byte>, pos: int) -> (int, u32)**
  - Parses a positive decimal integer from `a` starting at `pos`.

#### Hexadecimal Parsing
- **parse0xHex(a: Array<byte>, pos: int) -> (int, u32)**
  - Parses a hexadecimal integer prefixed with `0x` or `0X` from `a` starting at `pos`.
- **parseHex(a: Array<byte>, pos: int) -> (int, u32)**
  - Parses a hexadecimal integer from `a` starting at `pos`.

#### Binary Parsing
- **parse0bBin(a: Array<byte>, pos: int) -> (int, u32)**
  - Parses a binary integer prefixed with `0b` or `0B` from `a` starting at `pos`.
- **parseBin(a: Array<byte>, pos: int) -> (int, u32)**
  - Parses a binary integer from `a` starting at `pos`.

#### Rendering
- **renderDecimal(val: int, a: Array<byte>, pos: int) -> int**
  - Renders `val` as a decimal at `pos` in `a`.
- **renderPosDecimal(val: u32, a: Array<byte>, pos: int) -> int**
  - Renders a positive integer `val` as a decimal.

#### Additional Utilities
- **log(i: u32) -> int**
  - Computes the logarithm base 2 of `i`.
- **popcnt(i: u32) -> int**
  - Counts the number of 1 bits in `i`.
- **min(a: int, b: int) -> int**
  - Returns the minimum of `a` and `b`.
- **abs(a: int) -> u32**
  - Computes the absolute value of `a`.

### IntParseResult Enum
Defines result codes for integer parsing operations, such as `OK`, `OVERFLOW`, `UNDERFLOW`, `TOO_LONG`, and `EMPTY`.

## Longs Component

### Methods Overview

#### Decimal Parsing
- **parseDecimal(a: Array<byte>, pos: int) -> i64**
  - Parses a decimal long integer from `a` starting at `pos`.
- **parsePosDecimal(a: Array<byte>, pos: int) -> u64**
  - Parses a positive decimal long integer from `a` starting at `pos`.

#### Hexadecimal Parsing
- **parse0xHex(a: Array<byte>, pos: int) -> (int, u64)**
  - Parses a hexadecimal long integer prefixed with `0x` or `0X` from `a` starting at `pos`.
- **parseHex(a: Array<byte>, pos: int) -> (int, u64)**
  - Parses a hexadecimal long integer from `a` starting at `pos`.

#### Binary Parsing
- **parse0bBin(a: Array<byte>, pos: int) -> (int, u64)**
  - Parses a binary long integer prefixed with `0b` or `0B` from `a` starting at `pos`.
- **parseBin(a: Array<byte>, pos: int) -> (int, u64)**
  - Parses a binary long integer from `a` starting at `pos`.

#### Rendering
- **renderDecimal(i: i64, a: Array<byte>, pos: int) -> int**
  - Renders `i` as a decimal at `pos` in `a`.
- **renderPosDecimal(i: u64, a: Array<byte>, pos: int) -> int**
  - Renders a positive long integer `i` as a decimal.

#### Additional Utilities
- **popcnt(i: u64) -> int**
  - Counts the number of 1 bits in `i`.
- **min(a: long, b: long) -> long**
  - Returns the minimum of `a` and `b`.
- **log(i: u64) -> int**
  - Computes the floor of the logarithm base 2 of `i`.

These components provide essential utilities for handling numerical data effectively in various programming contexts, enhancing capability for numerical operations and data processing.
