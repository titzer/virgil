# Extended Algebraic Data Types #

Virgil supports *open* (extensible) algebraic data types, allowing variant hierarchies to be extended with new subtypes declared separately from the original definition.

## Open variants ##

A variant may include a `case _` to mark it as *open*, or *extensible*.
An open variant accepts values from **subtype variants** (declared elsewhere) in addition to its own named cases.
The `case _` acts as the default for any value not matched by a named case, and may optionally define or override methods.

```
type Priority {
    case Low;
    case _;             // open: other types can extend Priority
    def level() -> int { return 0; }
}
```

## Subtype variants ##

A *subtype variant* is declared with a dotted name `A.B`, making it a specialization of an existing open variant.
The parent must have a `case _`.

```
type Priority.High {
    case Warning;
    case Critical;
    def level() -> int { return 2; }
}
```

Now `Priority.High.Warning` and `Priority.High.Critical` are valid `Priority` values.
A variable of type `Priority` can hold any case, including those from subtype variants.

```
var p: Priority = Priority.High.Warning;  // valid: High is a subtype of Priority
```

Subtype variants can themselves be open (with `case _`) and have their own subtypes, forming hierarchies of arbitrary depth.

## Methods and dispatch ##

Methods declared on a variant are inherited by its subtype variants and may be overridden.
A method declared in the `case _` body is inherited by all direct subtypes.

```
var p: Priority = Priority.Low;
p.level()   // 0: dispatches to Priority.level

p = Priority.High.Warning;
p.level()   // 2: dispatches to Priority.High.level
```

Dispatch is based on the runtime case of the value, so the right implementation is always called even when the variable has the parent type.

## Matching open variants ##

When matching a value of an open variant type, subtype variants may be named directly as match arms.
A match on an open variant **always** requires a `_` arm, since new subtypes may be added independently.

```
def describe(p: Priority) -> int {
    match (p) {
        Low  => return 0;
        High => return 1;
        _    => return -1;  // required: covers any other subtype
    }
}
```

Subtype names are written *unqualified* in match patterns — `High` rather than `Priority.High`.

You can bind and downcast the matched value using `name: SubtypePattern =>`:

```
def describe(p: Priority) -> int {
    match (p) {
        Low    => return 0;
        h: High => return h.level();  // h has type Priority.High
        _      => return -1;
    }
}
```

## Type method references ##

A method on a variant type `T` can be referenced as a function value using `T.m`, producing a function of type `T -> ReturnType` that takes a `T` value as its first argument.
Dispatch is virtual: the function dispatches to the correct override based on the runtime case.

```
var f = Priority.level;             // f: Priority -> int
f(Priority.Low)                     // 0
f(Priority.High.Warning)            // 2: dispatches to High.level
```

This also works with subtype names:

```
var g = Priority.High.level;        // g: Priority.High -> int
g(Priority.High.Critical)           // 2
```

Type method references can be stored, passed to other functions, or used in arrays just like any other function value.

## Narrowing to a subtype ##

From a value of the parent type, you can test and downcast to a subtype using the query (`?`) and cast (`!`) operators:

```
var p: Priority = ...;
if (Priority.High.?(p)) {                        // true if p is a Priority.High
    var h: Priority.High = Priority.High.!(p);   // downcast; only safe after ?
    return h.level();
}
```

`T.?(v)` returns `true` if `v` is an instance of subtype `T`.
`T.!(v)` performs the downcast and is only safe to use after a successful `?` test.

## Parameterized open variants ##

Open variants can have type parameters. A subtype variant passes through the same type parameters as its root — it must declare exactly the same number of type parameters.

```
type Result<T> {
    case Ok(v: T);
    case _;
}
type Result<T>.Err<T> {
    case Error(code: int);
}
```

You can also use the shorthand form, omitting the type arguments on the qualifier:

```
type Result.Err<T> {
    case Error(code: int);
}
```

Both forms have exactly the same meaning: `Err<T>` is a subtype of `Result<T>` and shares the same type parameter.

### Construction and type references ###

When constructing or referencing a parameterized subtype, type arguments can be provided through the parent or directly:

```
var a: Result<int> = Result<int>.Err.Error(404);   // type args on left
var b: Result<int> = Result.Ok<int>(42);            // type args on case
var c: Result<int>.Err<int>;                        // fully explicit
```

When the left side provides type arguments (`Result<int>.Err`), the subtype inherits them automatically.

### Matching parameterized subtypes ###

Match patterns on parameterized open variants work the same as non-parameterized ones — type arguments are inherited from the type being matched:

```
def unwrap<T>(r: Result<T>, fallback: T) -> T {
    match (r) {
        Ok(v) => return v;
        e: Err => match (e) {      // e has type Result<T>.Err<T>
            Error(code) => return fallback;
        }
        _ => return fallback;
    }
}
unwrap(Result.Ok<int>(42), 0)              // returns 42
unwrap(Result<int>.Err.Error(404), 7)      // returns 7
```
