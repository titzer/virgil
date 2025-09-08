# Virgil Implementation Guide: Garbage Collection

Virgil's memory safety critically relies on automatic memory management.
The compiler and runtime system work together to efficiently manage heap memory in a way that is seamless to application programs.

When compiling Virgil to targets that have built-in garbage collection, such as the JVM, the Virgil compiler reduces Virgil constructs to target constructs (e.g. Java classes) and relies on the target runtime system's garbage collector for automatic memory management.
In addition to simplifying the Virgil runtime, this allows interaction with the target platform's other automatically-managed data structures.

## Compiler/Runtime interface for GC

When compiling Virgil to native targets, like `x86` (or to portable but low-level targets like `wasm`) the compiler and runtime system must work together to manage memory.
Here, the compiler's primarily responsibility is to lay out objects and code to be inspectable to the garbage collector, while the runtime's system responsibility is to dynamically manage objects on the heap.
While "the compiler" clearly refers to the program (`v3c`, aka `Aeneas`) that translates Virgil to machine code, "the runtime system" refers to additional code added to the program's binary that implements all of the runtime services, including garbage collection.
The runtime is written in Virgil and is in a separate directory in the repository (typically `rt/\<platform\>/`).

The interface between the compiler and runtime revolves around the two agreeing on:

 * the size and location of regions containing pre-initialized heap
 * the size and location of regions containing the runtime heap
 * the size and location of header information in each object
 * the encoding of header information
 * the minimum size and alignment of objects
 * whether tagged pointers in objects or the stack are supported
 * which registers contain references at GC safepoints
 * whether interior pointers in objects are supported
 * whether the runtime system always supplies zero-initialized memory for allocation
 * the exact sequence of operations to allocate on the heap
 * the exact sequence of operations for read/write barriers
 * write barrier optimizability
 * which routines in the runtime handle slow paths
 * whether the runtime system supports threads

Thus, even though the runtime is developed and maintained along with the compiler, it necessarily places certain constraints on compiler decisions.
Conversely, the runtime system is constrained by compiler capabilities.

## Compiler responsibilities

The compiler makes representation decisions for a given program with consideration of the runtime's capabilities and assumptions.
For example, if the runtime system supports tagged pointers, more choices for representing variants are possible.
Otherwise, the compiler may need to box variant values more often.
Similarly, if the runtime system doesn't support references in registers at a GC safepoint, the compiler must spill them to the stack.

Overall, the primary responsibility of the compiler is to produce metadata that guides the garbage collector on precisely finding references in code, on the stack, and in the heap.
Additional metadata describes the layout of objects on the heap.
Thus, when making representation decisions, the compiler produces information that describes:

 * the layout of all objects, both in the pre-initialized heap and in the runtime heap, including:
   * object size and location of references within objects
 * the layout of generated machine code, including:
   * function boundaries
   * size and layout of stack frames at all possible GC safepoints
 * memory region organization
 * the location of current and end pointers for TLAB-style bump-pointer allocation

## Runtime responsibilities

The runtime's responsibilities are almost all, well, at runtime.
In particular it must:

 * allocate and initialize the arguments to the program's `main()` (e.g. box strings into `Array<string>`)
 * initialize the various memory regions (e.g. "from-space" and "to-space"), according to collector algorithm
 * handle slow path allocation (e.g. is a GC necessary or is a local bump-pointer region exhausted), according to collector algorithm
 * handle read/write barrier slow paths
 * allocate thread stacks and/or TLAB regions at thread creation, according to thread support
 * invoke collector algorithm routines, including:
  * scan for roots in the stack
  * scan for roots in the pre-initialized heap
  * mark, trace, copy and/or sweep objects and regions
  * recycle unused memory

To accomplish each of these tasks, the runtime uses metadata produced by the compiler.
This metadata is carefully laid out into a specific binary format, placed in a special read-only memory region, and pointers to specific data structures in that region are made available through the `CiRuntime` API.

## The `CiRuntime` component

`CiRuntime` stands for "(C)ompiler (I)interface to the (Runtime)".
This means that it is an interface *provided by the compiler* to the runtime.
This metadata is intended *only* for the runtime, and not meant for application code, though currently the compiler does not enforce this.
This interface is *not* provided on targets like the JVM, so `CiRuntime` is an unresolved type.
On native targets, however, the runtime system and garbage collector can refer to this interface as if it were a Virgil `component`.

Fields of this component related to GC are detailed below.
All of these fields are of type `Pointer` and represent either read-only addresses or pointers to read-write pointers that can be updated during execution.
The read-write pointers are often updated by code generated by the compiler, e.g. the current boundaries in a bump-pointer-style allocator.

Read-only region boundaries:

 * `HEAP_START`, `HEAP_END` - (read-only) start and end of the entire heap region
 * `CODE_START`, `CODE_END` - (read-only) start and end of the code region
 * `DATA_START`, `DATA_END` - (read-only) start and end of the initialized data region
 * `STACK_START`, `STACK_END` - (read-only) start and end of the initial stack region
 * `SHADOW_STACK_START`, `SHADOW_STACK_END` - (read-only) start and end of the shadow stack region

Read-only pointers to metadata:

 * `GC_STACKMAP_PAGES` - (read-only) start of the stackmap page-index table
 * `GC_STACKMAP_TABLE` - (read-only) start of the stackmap entries table
 * `GC_EXTMAPS` - (read-only) pointer to the start of the extended stackmap table
 * `GC_ROOTS_START` - (read-only) start of the roots bitmap entries
 * `GC_ROOTS_END` - (read-only) end of the roots bitmap entries
 * `GC_TYPE_TABLE` - (read-only) start of the type tags table

Pointers to read-write pointers, which are updated by compiled code and the runtime.

 * `HEAP_CUR_LOC` - (location of) read-write pointer to the current heap (allocation) region
 * `HEAP_END_LOC` - (location of) read-write pointer to the end of the current heap (allocation) region
 * `SHADOW_STACK_START_PTR` - (location of) read-write pointer to start of the current shadow stack
 * `SHADOW_STACK_CUR_PTR` - (location of) read-write pointer to the current shadow stack top
 * `SHADOW_STACK_END_PTR` - (location of) read-write pointer to the end of the current shadow stack

### Encoding of `CiRuntime` metadata

The compiler and runtime must agree on the *encoding*, i.e. the binary format of all metadata.
It's particularly important that this metadata be encoded in a space- and time- efficient format.

Key primitive types are:

 * the `length-bitmap#N` type: a N-bit word, where the highest `1` bit set indicates the length, and the remaining low-order bits represent a bitmap of that length. If bit `N` is set, then the low `N-1` bits represent an index into an entry in an extended table that encodes larger bitmaps.

### Organization of GC stackmap metadata

When an application thread is stopped for GC, each frame on its execution stack contains an instruction pointer representing at return address.
Every instruction pointer for a valid Virgil frame must be a *safepoint* where the GC can *precisely* locate all references on the stack, allowing it to move objects if necessary and update references.
The compiler generates GC stackmap metadata that has one entry per GC safepoint, necessitating a dense binary encoding to save memory.
Since it may be used on every GC when walking the stack, its performance critical for reducing pause time.

When the collector walks the stack of a thread, it begins at the topmost frame and loads the program counter (`pc`) from the frame.
It uses the `pc` as a key into the stackmap table, where it will find an entry that contains a `length-bitmap#32`.
It then applies the bitmap to the words of the stackframe, treating `1`s in the bitmap as references at the corresponding slot in the frame.
It then advances to the next frame, repeating the process all the way down the stack to the entrypoint of the thread.

The stackmap table is encoded so that one indexing operation and one binary search are required to find an entry.
It consists of two tables:

 * `GC_STACKMAP_PAGES` - an array of indexes into the `GC_STACKMAP_TABLE`
 * `GC_STACKMAP_TABLE` - an array of `#length-bitmap#20` + `offset#12` entries

Both tables are indexed by the `pc` and the entries are sorted by the `pc`.
To look up the entry for a given `pc`, the routine is (pseudocode):

```
def lookupSafepointStackmap(pc: Pointer) -> LengthBitmap20 {
  var page = (pc - CiRuntime.CODE_START) >> 12;
  var start_index = CiRuntime.GC_STACKMAP_PAGES[page];
  var end_index = CiRuntime.GC_STACKMAP_PAGES[page + 1]
  var offset = pc & 0xFFF;
  var entry = binarySearch(offset, &CiRuntime.GC_STACKMAP_TABLE[start_index], &CiRuntime.GC_STACKMAP_TABLE[end_index]);
  return entry;
```

Thus, we use the first table, the "page" table, to quickly find the two indices that denote the start and end entries for all safepoints on the same page of code memory.
We then binary-search the entries in the stackmap table for the entry with the matching offset.
Because all of the entries between these two indices are on the same page, their upper bits match; thus the table doesn't need to store their upper bits.
Instead, it uses those upper bits to store, in-line, a 20-bit length-bitmap for the frame.
(Though the page size is chosen to be `4096` (12 bits), this is not actually tied to the virtual memory page size; it could be larger or smaller.)

### Organization of GC roots entries

Similar to the GC stackmap metadata, the roots metadata allows the GC to find all references in the initial heap, including global variables (i.e. component fields) and the objects which have been serialized into the data section.
It is organized as a list of `offset` + `length-bitmap#32` pairs, where the `offset` is an offset into the `DATA` region.
It covers only the mutable fields in the data section, since immutable fields by definition have their referents already serialized into the data section and don't need to be scanned nor updated.

### Organization of the GC types table

The types table describes the layout for each kind of object that can be in the program heap.
There is an entry for every class and boxed (heap-allocated) variant.
Each type is given a number starting from `0` up to the number of heap-allocated types in the program, and an object's header word is simply this number (shifted left by 2 to accomodate two additional bits and be useful as a direct-index into the types table).
The compiler chooses numbers for classes and variants by considering subtyping trees in a pre-order fashion, ensuring that every class or variant is given both a number and an interval that includes all of its subclasses.
(Thus the heap type number is used by the compiler for casts as well.)

The entries in the types table are simply `length-bitmap#32`s.

## Semi-space GC details

The Cheney semi-space collector algorithm is well-known and is the simplest moving collector design.
It divides the entire heap into two halves, the "from-space" and the "to-space".
The program allocates into the from-space by using a bump-pointer allocation.
When the region is full, the collector is invoked and it traces from the roots in the initial heap and the stack, copying all objects into the to-space.
It uses the objects in the to-space as a queue for transitively traversing to find all reachable objects.
When the queue is finished, it then frees the entire from-space and flips them; the from-space becomes to the to-space and vice-versa.
Allocation resumes from the end of the (now flipped) from-space.

This collector design is extremely simplistic, but it works extremely well for short-running programs that don't trigger a GC.
Since it requires no write barrier, it has minimal mutator overhead.
Interestingly, the Virgil compiler itself is memory-efficient enough that a full bootstrap of the compiler (i.e. the compiler compiling itself) allocates just under half of the heap allotted, and thus does no GCs.

The Semispace GC is implemented entirely in terms of pointers.
It assumes the header layout agreed to with the compiler and uses the metadata as described above.

## Extending the GC in the runtime and applications

Other than performance, the Virgil garbage collector is invisible to programs.
However, there are some situations where the GC behavior needs to be extended.

When managing native resources that *must not leak* but are specifically tied to an object, it is a good idea to use the GC has a backup plan for freeing the resource.
Sometimes called "finalizers", this amounts to behavior that should get invoked when an object is considered no longer reachable by the GC.

Virgil has *no language support for finalizers*.
Instead, there is a `RiGc.registerFinalizer` method that can be called from applications to register a finalization function that runs when an object is garbage-collected.
The finalization function does not get a reference to the collected object--i.e. no "resurrection".
It is also not tied to the object's type; nothing has to be declared in the class's (or variant's) definition for an object to have a finalizer.
It's even possible to attach a finalizer to an array.
This is implemented entirely in the runtime, requiring no compiler support.

In other situations, in particular, in unsafe code like an efficient guest runtime system, a Virgil program might use unsafe features to encode references in memory not normally scanned by the GC.
In this case, the runtime system exposes a call `RiGc.registerScanner` that allows registering application-level code that will be called *during GC*, just after an object has been scanned.
The application can access arbitrary memory associated with the object and report new roots back to the GC.
This can be dangerous (to say the least), but a necessary part of a high-performance guest runtime system.
In particular, a guest runtime system can implement tagged values, even though the host language and runtime system don't support it.

## Future GC algorithms

Of course, GC performance critically impacts many applications.
In the future, Virgil can and will have more sophisticated garbage collection.
The roadmap is likely to include a parallel, generational mark-sweep collector and some form of concurrent collector.
Each of these requires a different write barrier that thus requires some compiler implementation work, in addition to the runtime work.
