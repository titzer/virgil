# Inline-if or Conditional Expressions #

Virgil III supports a version of the "conditional" expression that chooses one of two values based on a condition. The syntax diverges from C, C++, and Java _ternary operator_ `? :`. In Virgil, you can simply use the `if` keyword as the start of a conditional expression.

```

// with declared types
var a: int = if(1 > 0, 16, 27);  // == 16
var b: int = if(1 < 0, 17, 29); // == 29
// with type inference
var c = if(3 > 2, 46, 67);  // == 46
var d = if(4 < 1, 47, 69); // == 69```

## Short-circuit evaluation ##

The `if` expression evaluates the condition and _only_ the branch corresponding to the value of the condition.

```

def main() {
// if(e, t, f) evaluates e, then either t or f, not both
var a = if(true,  print(12), print(13));
var b = if(false, print(22), print(23));
}
def print(x: int) {
System.puti(x);
System.puts("\n");
}```

## False Default ##

The `if` expression allows you to omit the expression for the false case. For this form of the `if` expression, the whole expression will evaluate to the _default value_ of the appropriate type when the condition is `false`. This helps make many expressions much shorter.

```

// with declared types
var a: int = if(1 > 0, 17);	// == 17
var b: int = if(1 < 0, 19);	// == 0 (default)
// with type inference
var e = if(1 > 0, 37);	// == 37
var f = if(1 < 0, 39);	// == 0 (default)```

## Type inference ##

Type information from the left branch of an `if` expression can often be used to infer types in the right branch of an `if`-expression.

```

// with declared type
var a: Array<int> = if(true, [1], Array<int>.new(3));
// with type argument inference
var b: Array<int> = if(true, [], Array.new(3));
// with local type inference
var c = if(true, [1], Array<int>.new(3));```