# Layouts

Virgil is a language for writing systems software at the lowest level.
Such software often has to manipulate data in formats that are specified by software and hardware that cannot be changed.
For example, bootstrapping the language, implementing high-performance (zero-copying) I/O, and interacting with memory-mapped I/O devices requires reading and writing data in specific formats.
Prior to the introduction of layouts in Virgil, such interactions were done with byte-by-byte encoding or direct pointers.
With the addition of layouts, this code becomes easier and safer to write, making it a breeze to deal with data in binary formats.

## Specifying a memory layout

Layouts in Virgil are a new construct to describe the exact position and encoding of data fields within a small region.
A *layout* description is *not* a datatype; rather, it is a *view* on underlying storage, either in an `Array<byte>` or `Range<byte>`.
This decouples allocation and storage of layouts from the access of their fields.

Let's have a look at our first layout!

```
layout RGBAlpha {
       +0	red:	byte;	// red intensity 0...255
       +1	green:	byte;	// green intensity 0...255
       +2	blue:	byte;	// blue intensity 0...255
       +3	alpha:	byte;	// alpha channel (transparency)
       =4;			// total size = 4 bytes
}
```

This layout describes a view of pixel data that is common in image formats and graphics APIs.
Each field in a layout declaration has 1) an explicitly-specified offset from the beginning of the layout, 2) a name, and 3) a type.
Additionally, a layout description must also have a *total size* in bytes.

Bytes are key to understanding layouts.
Layout descriptions are *always* specified in terms of bytes and byte offsets, and never in terms of machine words, whose size and endianness would be architecture-specific.
Thus Virgil layouts are *machine and architecture independent*.

Virgil layouts also do not have implicit (automatic) alignment or juxtaposition.
Every field must have an explicit offset[^1].
While being a little more work to write, this allows for the most general descriptions, including skipping padding and choosing exact alignment.
The compiler will check that fields do not overlap or overflow the specified layout size.

[^1]: The offset of a field can be written in hexadecimal, which makes it easy to align, e.g. to powers of two.

## Allowable layout field types

Since layouts are used primarily as views over byte arrays and ranges, *all* of the fields in a layout must be types that have a transparent (i.e. architecture-independent) encoding into bytes.
Clearly, Virgil `byte` and `bool` types are easy enough; they map to a single byte in the underlying storage and have their straightforward binary encodings.
For Virgil fixed-width integers larger than a byte, the field storage occupies multiple bytes.
Unless specified otherwise, such integers are encoded as little-endian, two's complement.
Floating point numbers are allowed and are encoded in their respective IEEE formats.
Virgil enums are encoded as their respective tag type.

However, Virgil data types that are managed by the language, such as references to objects, tuples, or algebraic data types, have opaque representations and *cannot* be used in layout descriptions.
This is not only to protect the Virgil language's runtime memory safety, but also, such types could have many different encodings.
An easy rule to remember is that if a type has an unambiguous, fixed-length encoding into an actual Virgil byte array, then it can be put into a layout.

## Repeated fields in layouts

Every layout is a fixed-size view; there are no variable-sized layouts.
This is because many different file formats, data structure, network protocols, etc have different schemes for encoding lists or arrays or repeated sub structures.
However, repeated fields with a fixed number of elements can be specified.

```
// A view of a (maximum 15-byte) string.
layout FixedString15 {
       +0       length:   byte;
       +1       name:     byte[15];
       =16;
}

var data = Array<byte>.new(16);
var str = Ref<FixedString15>.of(data);
var last = str.name[str.length - 1];     // access is dynamically bounds-checked against 15
```

Repeated fields allow expressing fixed-size arrays inside a layout.
Accesses to repeated fields are indexed with `[]` and the index is bounds-checked against the statically-declared number of elements in the field.

## Field Overlapping and Memory Skipping in Layouts
In Virgil layouts, field overlapping within a layout is strictly prohibited to prevent data corruption and ensure data integrity. Each field must have a unique, non-overlapping byte offset. 

```
layout DeviceRegister {
       +0    command:   u16;    
       +1    status:    u16;    // Overlaps, illegal
       =3;                    
}
```
However, Virgil layouts allow skipping regions of memory within the layout.
```
layout DeviceRegister {
       +0    command:   u16;    // Command field, 2 bytes
       // skipped 2 bytes
       +4    status:    u16;    // Status field, 2 bytes
       =6;                       // Total size = 6 bytes
}
```
## Overlaying layouts on byte arrays (`Ref.at` and `Ref.of`)

A layout in Virgil is not a data structure, but instead a view on underlying storage.
To read and write data fields through a layout, a `Ref` must be created by overlaying a layout on valid storage, such as an already-allocated byte array or range.
These references have the Virgil types `Ref<L>` or `ref<L>`, which represent a read-write or read-only view of a layout `L` on underlying storage.

Building on the RGB example, we can create a view of a particular pixel and manipulate it:

```
def image = Array<byte>.new(1024);		// underlying storage of image is bytes
var pixel = Ref<RGBAlpha>.at(image, 12);	// view bytes 12...15 as an RGBAlpha layout

def increaseRed(p: Ref<RGBAlpha>) {
    p.red *= 2;					// update the red channel in place
}
```

Here, we create a view of a particular pixel with the `Ref.at` operator.
This operation does a one-time null and bounds check of the input array and index, checking that enough storage exists to have a complete `RGBAlpha` view (i.e. `4` bytes) at the given offset of `12`.
Thereafter, a read or a write to any field through that reference requires no bounds checks or null checks.

## Nesting layouts

Layouts can be nested inside other layouts.
When a layout is nested, it is "inlined"; i.e. flattened.
This allows decomposing complicated layouts into smaller, reusable constructs.
For example, many file formats allow the same kind of construct to appear in different places.
Nested structs are simply declared using the name of the layout as the field type.

```
layout Nested {
       +0     value:	u32;
       +4     kind:	u16;
       =6;
}
layout FooBar {
       +0     n:	Nested;
       +6     m:	Nested;
       =12;
}
var x = Ref<FooBar>.of(Array<byte>.new(12));
var y: Ref<Nested> = x.n;			// x.n is nested inside x
var z: Ref<Nested> = x.m;			// x.m is nested inside x
```

Accessing a nested layout is like accessing any other field; we simply use the member access (`.`) operator.
Since the outer layout is a `Ref` (or `ref`), the inner access produces a `Ref` (or `ref`, respectively) to the inner layout.
Thus chaining accesses is exactly like regular field accesses.
Accessing nested layouts incurs no additional safety or bounds checks, since creation of the outer reference bounds-checked the entire outer layout.

## `Ref<L>` doesn't allocate

References (`Ref<L>` and `ref<L>`) are really views on underlying storage.
Using references does not create new objects on the heap.
Virgil represents these values as a pair `(Array<byte>, int)`, i.e. *two* values, and the compiler simply rewrites the internal representation of the program to use two values everywhere they occur, i.e. flattened, exactly as tuples.
Of course, the internal representation of a reference, including the original array cannot be recovered, so a reference is a secure, unforgeable handle to a restricted part of the original array.

Because creating a `Ref` from an underlying byte array or range does not allocate additional objects on the heap, they can be used with wild abandon.
Feel free to use them in high-performance situations, such as looping over large image data, high-volume I/O, etc, as they do not create garbage collection pressure!

## `Ref<L>` is safe

Because references are simply views over byte arrays, they do not require any memory-unsafe constructs to be implemented.
Conceptually, every access to a reference field could be implemented as a byte-by-byte read or write.
And this even works on Virgil compilation targets (like the JVM) that have no notion of `Pointer`!
On native targets, the implementation may be more efficient, performing word-sized reads and writes and avoiding bounds checks when possible.
In fact, a reference access on a native target is simply an `add` of the underlying array and index and then a `load` or `store`--two instructions!

## Endianness

By default, unless specified otherwise, Virgil fixed-width integers are encoded into layout fields in little-endian byte order.
Some file and network formats, or layouts specified by a kernel on a big-endian target, may be in big-endian order.
To support this, Virgil has a `#big-endian` modifier for both layouts and fields that overrides the default.
The Virgil compiler will transparently perform endianness conversion when reading and writing these fields.

## Off-heap layouts

Layouts allow a Virgil program to specify an exact layout of a data structure that uses primitive data.
As we saw, layouts are used with `Ref<L>` to overlay a view on an underlying byte array (or range).
They are particularly useful for dealing with hardware and software that have binary data structures, like an underlying OS kernel.
Often, these data structures are not, and can't be, in the Virgil heap or Virgil byte arrays, which may be moved at any time by the Virgil GC.
With off-heap `Range` types, Virgil now supports using `Ref<L>` to refer to data that is stored off-heap, e.g. in the execution stack or memory-mapped files, shared memory, etc.
This allows Virgil code to be written agnostic of whether the data they manipulate through references is stored in the heap or off of the heap!
