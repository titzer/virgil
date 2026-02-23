# Function Expressions - fun-exprs #

Virgil III supports functional programming with first-class functions that allow small-scale reuse.
As we've seen, Virgil supports [functions](Functions.md) which are simply values that refer to methods.
All methods, including those at the top-level, those belonging to a component, those belonging to a class, or to a specific object, can be used as a value.

As we've also seen, any function can be [partially-applied](PartialApp.md), where we can supply some arguments and not others.
Partial application is great to adapt a function accepting many parameters to a place where a function accepting only a few parameters is expected.

## Function Expressions are Lambdas ##

With Virgil III-10, new syntactic support for functions has been added that allows us to write very succint functional code, right where we need it.
We call these "function expressions" (or fun-exprs), since they can be used in an expression context.
Programmers with a functional background will recognize that Virgil function expressions are *lambdas*.

```
// Enumerate the first 4 primes to the function {f}.
def doPrimes(f: int -> void) {
    for (prime in [2, 3, 5, 7]) f(prime);
}
def main() {
    // Pass a function to {doPrimes} that prints a nicely-formatted line.
    doPrimes(fun p => System.puts(Strings.format1("Prime: %d\n", p)));
}
```

In our first example, we have a function `doPrimes` that enumerates the first four prime numbers to a function that is passed as an argument.
In the main function, we use the enumeration function and pass a function expression that prints each prime to the output using formatting utilities.
The function expression is introduced with the `fun` keyword, followed by the declaration of any parameters the function accepts.
In this case, the function accepts a prime number parameter, which we name `p`.
The body of the function follows the `=>`, which is simply an expression that calls `System.puts`.
(This last part is a [simple function body](SimpleBodies.md), which has its own tutorial).

## Parameter Type Inference ##

Notice that in the first example, unlike other Virgil methods, we didn't have to write the type of the parameter `p`--the compiler inferred it!
Parameter type inference allows us to write more succint function expressions, but fun-exprs can also have explicit parameter types when needed.
We could have written a more explicit version where the parameter has a declared type:

```
def main() {
    // Pass a function to {doPrimes} that prints a nicely-formatted line.
    doPrimes(fun p => System.puts(Strings.format1("Prime: %d\n", p)));
    // Same as above, but explicitly declare the parameter type.
    doPrimes(fun (p: int) => System.puts(Strings.format1("Prime: %d\n", p)));
}
```

## Multi-parameter function expressions ##

Function expressions that accept multiple parameters can be declared using syntax similar to declaring multiple parameters to a method.
We simply put the parameters in parentheses.
The compiler can still infer parameter types when there is enough context.
If not, we can always add explicit parameter types.

```
def doPairs(f: (int, int) -> void) {
    // Iterate over some pairs of integers, applying {f} to each.
    for (pair in [(1, 2), (2, 3), (3, 4)]) f(pair);
}
def main() {
    // Pass a function to {doPairs} that prints a nicely-formatted line.
    doPairs(fun (x, y) => System.puts(Strings.format2("Pair: %d and %d\n", x, y)));
    // Same as above, but explicitly declare the parameter types.
    doPairs(fun (x: int, y: int) => System.puts(Strings.format2("Pair: %d and %d\n", x, y)));
}
```

## Function Expression Bodies With { ... } ##

In the examples so far, the function expressions we passed to our helper functions had pretty simple bodies--just a couple of nested calls.
But what if the bodies of the function we want to pass are complex, and want to do control flow, like an `if` or a `match`?
In this case, instead of the `=>`, we can use `{` ... `}` which introduces a *block*, allowing us to write complex statements.
We could then write a more explicitly sequential version (avoiding the `Strings.format1` utility):

```
// Enumerate the first 4 primes to the function {f}.
def doPrimes(f: int -> void) {
    for (prime in [2, 3, 5, 7]) f(prime);
}
def main() {
    // Pass a function to {doPrimes} that prints a nicely-formatted line.
    doPrimes(fun p {
        System.puts("Prime ");
        System.puti(p);
        System.ln();
    });
}
```

When we use a block for the body of a function expression, the return type of function is implicitly `void`.
This matches the behavior of methods in Virgil which implicitly return `void` if they have no return value.
Yet we can also explicitly specify a return type as well.

## Explicit Return Types with `->` ##

Like methods, function expressions in Virgil that have blocks as their bodies can have their return type explicitly declared.
This is needed when writing complex function expression bodies that return a value, or when the compiler cannot infer the return type from context.
For example, suppose we wanted to return a value to `doPrimes` to terminate early.
With block body syntax and an explicit return type, we can do so:

```
// Enumerate primes until {f} returns false.
def doPrimes(f: int -> bool) {
    for (prime in [2, 3, 5, 7, 11, 13]) {
        var keep_going = f(prime);
        if (!keep_going) break;
    }
}
def main() {
    // Pass a function to {doPrimes} that prints a nicely-formatted line.
    doPrimes(fun p -> bool {
        System.puts("Prime ");
        System.puti(p);
        System.ln();
        return p < 3; // stop after 3.
    });
}
```

## Automatic Variable Capture ##

In most functional languages, lambdas automatically capture variables from their outer contexts.
Referred to as "free variables", the compiler will arrange for closures to store the values of outer variables when captured.
Some languages like C++ and Rust require explicit declarations of variable capture to make closure cost and resource management more explicit.

Since Virgil's first class function supported pre-dates its support for function expressions, it has long featured garbage-free functional programming with delegates, where programmers can instead use objects as closures.
Thus the addition of function expressions is viewed as a syntactic convenience worthy of tersity.
Thus Virgil follows functional languages and features automatic variable capture.
Sometimes, the compiler can automatically optimize closures to avoid allocating storage space on the heap.
Otherwise, function expressions will allocate closures when they need to capture variables which will then be garbage-collected transparently.

```
// Enumerate the first 4 primes to the function {f}.
def doPrimes(f: int -> void) {
    for (prime in [2, 3, 5, 7]) f(prime);
}
def printPrimesIn(low: int, high: int) {
    // Print out the prime if it's in the range.
    doPrimes(fun p {
        if (p < low || p > high) return; // low and high are captured from the outer context.
        System.puts("Prime ");
        System.puti(p);
        System.ln();
    });
}

```

## Capturing Mutable Local Variables ##

For imperative languages like Go and Java that have added functional features after their initial release, capturing mutable local variables can be confusing and cause bugs.
For example, confusing behavior can result when referring to the induction control variable in a lambda nested inside the loop.

Instead, Virgil simply *disallows* capture of mutable local variables and considers loop control variables to be *immutable*.
This means two things: function expressions only capture copies of local variables (no heap indirection for mutating locals), and innocent-looking code that closes over loop variables has no surprising behavior.

