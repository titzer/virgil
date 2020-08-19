# Tuples and Methods #

Virgil treats tuples in a uniform way that makes it easy to write methods that take tuples as parameters or return tuples as values.

## Multiple parameters are one tuple ##

Virgil treats multi-argument functions as if they accepted a tuple of the individual parameters. That means that passing a single tuple or multiple values are both perfectly legal.

```

def main() {
var t = (3, 4);
// both individual parameters and a single tuple are equivalent
m1(3, 4);
m1(t);
// both individual parameters and a single tuple are equivalent
m2(3, 4);
m2(t);
}
def m1(a: int, b: int) -> int {
return a + b;
}
def m2(t: (int, int)) -> int {
return t.0 + t.1;
}```

## Chaining tuple-return invocations ##

Because passing a single tuple parameter is equivalent to passing individual arguments, it is now easy to chain together invocations of methods that return tuples with invocations of methods that accept tuples as arguments:

```

def f() -> (int, int) {
return (3, 4);
}
def g(a: int, b: int) {
System.puti(a);
System.puti(b);
System.puts("\n");
}
def main() {
g(f()); // f returns a tuple, and g accepts a tuple
}```

## Implementation notes ##

It may seem that treating all multi-argument functions as accepting tuples would result in unnecessary inefficiency. In fact, it's exactly the opposite. All tuples are rewritten into individual parameters and are never allocated on the heap; both forms result in efficient machine code that passes parameters in registers and on the stack.