# The Vastly Oversimplified Language Comparison Page #

Virgil is a different approach to language design. Here's how it compares to some other languages and their implementations.

# C #

Unlike C, Virgil has classes to support encapsulation and aid in building complex data structures. It is type and memory safe, has no pointers`*` or header files, has platform-independent semantics with no undefined behavior, automatic memory management, and has support for functional programming.

# C++ #

Unlike C++, Virgil is type and memory safe. Virgil has no pointers [1], header files, or templates. Like C++, Virgil's parametric type system supports primitives as type arguments and distinguishes, for example, `List<int>` from `List<string>`. However, Virgil has separate type checking, efficient and minimal runtime type information, and the compiler generates error messages that are short and comprehensible. Virgil is a substantially simpler language than C++. It does not support multiple inheritance, destructors, or template specialization, and only the indexing operator `[]` can be overloaded.

Like C++, the Virgil compiler can generate efficient binaries to run on native platforms, but it can also run on the JVM and WebAssembly.

# Java #

Unlike Java, Virgil is designed with efficient static compilation in mind. Memory efficiency and startup time are important! Virgil does not erase type arguments and allows any type to be used as a type argument. Type parameters are _reified_ in the sense that `List<String>` can be distinguished from `List<int>` at runtime. It has powerful local type inference, better initialization rules for classes, tuples, and better array syntax. Virgil does not have reflection or dynamic class loading, which vastly reduces metadata and enables more powerful compile-time optimizations. Virgil also has a clean separation between what types are in the language and what are in the libraries. Virgil can run on the JVM but doesn't require a virtual machine; it can be compiled to efficient, standalone native binaries.

# Python #

Unlike Python, Virgil is statically typed, which catches more errors at compile time. Class metadata and members are not mutable. The syntax is closer to Java and C++ and is not whitespace-sensitive. Virgil programs run much faster than Python, particularly when compiled to native binaries.

# Go #

Unlike Go, Virgil has real support for object-oriented programming with encapsulation, inheritance, parametric types, and whole-program compilation. Virgil syntax looks a lot more like familiar languages like Java and C than Go does. Virgil does not support structural typing or coroutines, pointers`*`, or array slices. Virgil has better support for a functional programming style and compiles to smaller binaries than Go. Its runtime system and garbage collector are implemented in Virgil, unlike Go which requires a large amount of supporting C code.

# Rust #

Unlike Rust, Virgil is a garbage-collected language. It has no need of ownership or destructors, which complicate APIs with distracting and irrelevant memory management details.

# Tuples and Algebraic Data Types #

Unlike the above languages, Virgil has proper tuples and algebraic (sum) types, in addition to its class and object system. ADT values do not have identities and can be pattern-matched and tuples allow easily passing and returning multiple values in a lightweight (i.e. no-type-declaration-required) way.

[1] Actually, Virgil does have pointers, but only in a platform-dependent dialect in which the runtime system is written. Application-level programs should never need or use pointers.
