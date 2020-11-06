# Functions #

Functions are values which refer to methods.

The syntax for writing function types is reminiscent of how we declare methods. We simply write `T -> T` to represent a function type. The first type represents the parameter type and the second represents the return type.

```

// methods can be used as first class functions
var x: int -> int = m1;
var y: int -> int = m2;

def m1(a: int) -> int {
return a + 1;
}
def m2(a: int) -> int {
return a + 2;
}```

## Invocation ##

Invocation of functions is just as for methods. We simply write the expression that represents the function followed by the arguments in parentheses `( ... )`

```

def main(a: Array<string>) {
var f: (int, int) -> int;
if (a.length > 0) f = m1;
else f = m2;
f(0, 2); // invocation of first-class function
}
def m1(a: int, b: int) -> int {
System.puti(a);
System.puts("\n");
return a + b;
}
def m2(a: int, b: int) -> int {
System.puti(b);
System.puts("\n");
return a + b;
}```

That means we can also chain invocations, for example if a function returns a function:

```

def m() {
// chained invocation of function returned from f
f(2, 3)(3);
}
def f(a: int, b: int) -> (int -> void) {
return g;
}
def g(a: int) {
}```

## Multi-argument functions ##

Methods that take multiple values are usable as functions that take a _tuple_ as a parameter. Here, the composability of tuple types makes perfect sense and we can see the syntax of declaring methods mirrors the syntax of function types.

```

// multi-argument functions have a tuple as their parameter type
var a: (int, int) -> int = m1;
var b: (int, int, int) -> int = m2;

def m1(a: int, b: int) -> int {
return 2 * a + b;
}
def m2(a: int, b: int, c: int) -> int {
return 2 * a + b - c;
}```

## Multi-return functions ##

Tuples and functions together make for powerful reusability. With tuples we can easily return multiple values from a function and seamlessly pass the result to the next function, just as we did for [methods](TutorialTuplesAndMethods.md).

## Composability ##

Function types are just like any other type in Virgil: they are completely composable. If `T1` and `T2` are valid types, then `T1 -> T2` is a valid function type. No exceptions!

```

// any type can be used the parameter or return type
var a: Array<byte> -> void;
var b: Array<byte> -> int;
var c: (void, void) -> (int, int);
var d: Array<(void, void)> -> byte;
var e: int -> int -> int;
var f: (int -> int) -> int;
var g: int -> (int -> int);```

Of course, function types can legally appear where any other type can appear. That means that we can make tuples of functions, arrays of functions, etc.

```

var a: Array<int -> int>;
var b: (int -> int, void -> int);
var c: Array<(int -> int, void -> int)>;```

## Primitive Functions ##

All of the primitive arithmetic operators are available as functions. These can come in handy if, for example, you want to sort an array of integers and have a `sort` routine that needs a function to compare the values.

```

var add: (int, int) -> int = int.+;
var sub: (int, int) -> int = int.-;
var mul: (int, int) -> int = int.*;
var div: (int, int) -> int = int./;
var mod: (int, int) -> int = int.%;
var and: (int, int) -> int = int.&;
var or: (int, int) -> int  = int.|;
var xor: (int, int) -> int = int.^;
var shl: (int, int) -> int = int.#<<;
var shr: (int, int) -> int = int.#>>;

var lt: (int, int) -> bool   = int.<;
var lteq: (int, int) -> bool = int.<=;
var gt: (int, int) -> bool   = int.>;
var gteq: (int, int) -> bool = int.>=;```

```

var lt: (byte, byte) -> bool   = byte.<;
var lteq: (byte, byte) -> bool = byte.<=;
var gt: (byte, byte) -> bool   = byte.>;
var gteq: (byte, byte) -> bool = byte.>=;```

```

var and: (bool, bool) -> bool = bool.&&;
var or: (bool, bool) -> bool  = bool.||;```

## Equality and Inequality functions ##

Recall that every type `T` has associated equality `==` and inequality `!=` operators that compare values of the type. These operators are available as functions using the `T.==` and `T.!=` syntax `*`.

```

var a: (int, int) -> bool = int.==;
var b: (int, int) -> bool = int.!=;
var c: (byte, byte) -> bool = byte.==;
var d: (byte, byte) -> bool = byte.!=;
var e: (bool, bool) -> bool = bool.==;
var f: (bool, bool) -> bool = bool.!=;
var g: (void, void) -> bool = void.==;
var h: (void, void) -> bool = void.!=;
var i: (Array<byte>, Array<byte>) -> bool = Array<byte>.==;
var j: (Array<byte>, Array<byte>) -> bool = Array<byte>.!=;```

`*` note that some types are currently not supported on the left hand side of the member operator `.` These functions can be accessed through a [parameterized](TutorialTypeparams.md) method, however.

## Array functions ##

Arrays also provide some basic functions to get the length of an array and to create a new array. The `length` member of each array type represents a function that takes an array of that type and returns its length. Similarly, the `new` member of each array type allocates a new array of that type given the length as its first parameter.

```

// a function that gets the length of an array
var a: Array<int> -> int = Array<int>.length;

// a function that allocates an array of int
var b: int -> Array<int> = Array<int>.new;

// every Array<T> type supports these functions
var c: Array<string> -> int = Array<string>.length;
var d: int -> Array<string> = Array<string>.new;
var e = Array<byte>.length;
var f = Array<byte>.new;```

## Future Compatibility ##

Virgil doesn't currently support lambdas, but support will be added soon.