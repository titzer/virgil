# Simple bodies #

Virgil III-10 introduces new syntax for writing more succint method bodies using the `=>` operator.
This helps us write more terse examples and utilities and generally improves code density.
The new syntax allows a method's implementation to consist solely of an expression, rather a return type, a block, and a `return` statement.

## Return Type Inference ##

Simple bodies rely on the compiler to perform type inference.
The return type of a method whose body is simple will become the type of the expression representing the body.

```
def add1(x: int, y: int) -> int {
    return x + y;
}
def add2(x: int, y: int) => x + y; // return type inferred from expression
```

This works even if the simple body is a call to another method.

```
def add1(x: int, y: int) => x + y;              // inferred return type from int + int
def sub1(x: int, y: int) => add1(x, 0 - y);     // inferred return type from add1
```

## Inherited methods ##

Simple bodies work with top-level methods, component methods, and class methods.
That means that inheritance of methods with simple bodies works as normal; the only difference is that the compiler infers the return type.

```
class C(x: int) {
    def plus(v: int) => x + v;          // inferred to return int
}
class D extends C {
    new(x: int) super(x) { }
    def plus(v: int) => x + 2 * v;      // inferred to return int, which is a legal override
}
```
