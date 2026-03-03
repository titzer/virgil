# Linking to external code

By default, the Virgil compiler produces complete standalone executable files when compiling to native targets.
For other targets, it produces self-contained binaries such as `.jar` files or `.wasm` files.
However, Virgil programs can explicitly *export* specific Virgil functions for external code to call, and explicitly *import* external functions for Virgil code to call.

## Exporting functions

Virgil only allows functions to be exported--not variables, fields, objects, classes or types.
Exported functions must be exported via a top-level declaration in several ways.

A program may mark a function for export directly in its declaration:

```
export def func1_to_export(x: int) -> bool { ... }
```

It is also legal to mark a function for export in a separate statement:

```
def func2_to_export() -> int { ... }
export func2_to_export;

def func3_to_export(i: int) -> int { ... }
export func3 = func3_to_export;

component MyComponent {
    def func4_to_export(b: bool) -> int { ... }
}
export func4 = MyComponent.func4_to_export;
```

For `func1_to_export` and `func2_to_export`, the Virgil name and the exported name of the functions are the same.
However, in the `export name = ...` form, `name` is the external name.
It is also possible to indicate an arbitrary external name (one that need not follow Virgil's rules for a legal identifier) with an explicit string:

```
export "func@6" def func6_to_export() { ... }

def func7_to_export() { ... }
export "func$7" = func7_to_export;
```

Virgil does not emit any type information for exported (or imported) functions.
It is the programmer's responsibility to make sure types match.
An important rule to understand and follow is that **all** Virgil functions, even top-level and component functions, take a receiver, also know as the `this` argument.
Under the hood, all function calls in Virgil pass a receiver argument.
While the Virgil compiler optimizes component functions to no longer use their receiver argument, it is still present in the calling convention.
Thus, calling top-level and component functions from external code must supply a receiver.
A `null` value is suitable.

For example, if in Virgil we have

```
export def increment(i: int) -> int { return i + 1; }
```

then in C we can declare and call this exported Virgil function like this:

```
#include <stddef.h> // to get NULL
extern int increment(void *ignored, int i);

... x = increment(NULL, 17); ...
```

### Restrictions on exported functions

* Programs cannot export parameterized function that have *unbound* type parameters.
Thus, this is illegal:

  ```
  export def f<T>(x: T) { ... }
  ```

  However, exporting a specific instantiated function is ok:

  ```
  def f<T>(x: T) { ... }
  export f_int = f<int>;
  export f_bool = f<bool>;
  ```

* A platform may restrict the allowed / safe argument and result lists of imported and exported functions, and functions passed back and forth at run time.
This typically has to do with imperfect matches between the register usage and calling conventions of Virgil and of other languages on the given platform.
See the notes on [platform-specific details](#platform-specific-details).

* Exported functions are roots for determining reachability of declarations and code, so they will never be optimized away.

* `main` functions are exported automatically, and a file level `main` will be marked as the entry point of the program.
However, a program that has exports or imports need not have a `main`.
For example, the `main` might be in external code or some other compiled module.

* Virgil remains a whole program compiler.
In principle you can use exports (and imports) to create and link together multiple Virgil modules, but the libraries are not currently designed to avoid ending up with multiple copies of the same library functions, etc.
Further, depending on the platform, separate modules might all demand to be loaded at the same address, implying that such platforms support only one Virgil module per program.
The compiler supports the `-vm-start-address` option to manually place sections.

## Importing functions

You may indicate one or more functions to *import* from external code using the `import` keyword on a component:

```
import component MyImports {
    def import1(i: int) -> bool;
    def import2(u: u64) -> float;
}
```

Such components must contain only methods, and the methods must not have type parameters.
The imported names are formed from the concatentation of the component name and the function name, separated by a dot `'.'`.
Thus the two functions imported in the example must have names `MyImports.import1` and `MyImports.import2`.
Since external modules may be written in languages with different rules for function names, Virgil allows strings for names, as in:

```
import "mine" component MyImports {
    "imp1" def import1(i: int) -> bool;
    ...
}
```

This would lead to the external name `mine.impl1`.
If the dot is problematic, you can also write:

```
import "" component MyImports {
    def import1(i: int) -> bool;
}
```

and the external version of the imported names will omit both the component name and the separating dot.
In that way you can match any external name for the function.

As we saw, all Virgil functions have a receiver, even if optimized component functions ignore it.
However, for convenience, Virgil will automatically adapt imported functions with a stub that discards the receiver before calling the external function.
Thus external functions do not need to declare a receiver, and the following C code can be used to supply the import from above:

```
int import1(int i) {
    return i > 0;
}
```

## Passing functions at run time

Functions (actually their code addresses) may be passed at run time using two provided `CiRuntime` functions, as we now illustrate.

First, let us get a pointer to a Virgil function, which we can then pass to a C function.

```
def increment(x: int) -> int { return x + 1; }

def getIncrement() -> Pointer {
    // A Virgil closure consists of a Pointer to the function code and
    // a pointer to the "this" value, which in this case is always void.
	var closure: (Pointer, void) = CiRuntime.unpackClosure(increment);
    var fp = closure.0;
    CFunctions.incrementCaller(fp);
}

import "" component CFunctions {
    def incrementCaller(func: Pointer);
}

```

The C side of this interaction might be:

```
int x = 17;
void incrementCaller(int(*func)(void *, int)) {
    x = (*func)(NULL, x);
}
```

The argument to `CiRuntime.unpackClosure` need not be a specific function known at compile time.
The type parameters of `CiRuntime.unpackClosure` are, in order: the type of the receiver of the function (`void` here because it is
a component function), the type of the function's parameter list, and the type of the function's result list.
There are omitted here because in this case they can be inferred.
`CiRuntime.unpackClosure` returns a pair of a `Pointer` to the function's code and the receiver value (here always `void`).

Given a `Pointer` to a function, we can construct a Virgil closure that can be used to call the function by using `CiRuntime.forgeClosure`:

```
import "" component CFunctions {
    def getFunc() -> Pointer;
}

def getAndCallFunc(x: int) -> int {
    var fp = CFunctions.getFunc();
	var f: int -> int = CiRuntime.forgeClosure(fp, ());
	return f(x);
}
```

Here, `fp` is a `Pointer` to an external function that takes an ignored "this" argument and an `int` and returns an `int`.
The first argument to `CiRuntime.forgeClosure` is the `Pointer` to the function's code and the second argument is the "this" value, which here is `void` (written `()`, that is, an empty tuple).
`CiRuntime.forgeClosure` returns a Virgil closure, which is a callable function, as indicated by the call `f(x)`.
Here is sample C code for `getFunc`:

```
int twice(int i) {
    return i + i;
}

typedef int (*FP)(void *, int);

FP getFunc() {
    return &twice;
}
```

## Platform-specific details

### x86-64-linux

For all Linux targets, the Virgil compiler emits ELF binaries, and for `x86-64`, imports and exports conform to the System V x86-64 ABI.
There are no limitations on number or kind of parameters passed to a function (though it is dangerous to pass references to Virgil heap objects and Virgil makes no guarantees that a garbage collector will not move or reclaim them) or about their internal format.
A function used across the interface may have zero or one return value, with the same caveats.

In the absence of exports or imports, the Virgil compiler generates a standalone executable.
The presence of exports and imports automatically causes the compiler to produce a `.o` file rather than an executable.
At present the code and data of these `.o` files reside at compiler selected virtual addresses (which can be controlled using compiler command line arguments) and must be loaded at that address in the linked executable by including a custom `ld` script like this one:

```
SECTIONS
{
  .text.virgil .text.virgil.base : { *(.text.virgil) }
  .data.virgil .data.virgil.base : { *(.data.virgil) }
  . = ALIGN(0x1000);
  _start = DEFINED(.entry) ? .entry : (DEFINED(_start) ? _start : 0);
}
INSERT BEFORE .text
```

Here, `.text.virgil.base` and `.data.virgil.base` are symbols that the compiler emits to indicate where the Virgil code and data should be placed.
If this script is called `virgil-ld-script`, then when linking a Virgil `.o` file the `ld` linker must be invoked using a command such as this:

```
gcc -m64 -no-pie -T virgil-ld-script -z noexecstack ... .o files ... -o executable-file
```

### x86-linux ###

While the Virgil compiler uses ELF format for this platform, the calling conventions, specifically whether and how registers are used to pass arguments and return results in function calls, do not match with those of `gcc`, etc.
There is no universal standard for this platform and the Virgil compiler passes arguments in registers to improve performance.
A means to generate adapters to support exports and imports for code generated by `gcc` is a future goal.

### Mac OS targets ###

The Mac OS linker format is not currently supported for imports and exports.

### JVM ###

External linkage is not currently supported for this platform.

### Wasm and Wasm-Gc ###

The Virgil compiler supports imports and exports for the `wasm` and `wasm-gc` targets.
The number of return values of imported or exported functions should be no more than one, to respect a current limitation of Virgil's Wasm/Wasm-Gc code generator.
