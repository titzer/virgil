# Logical Operators #

Logical operators allow joining multiple boolean expressions. Like C/C++ and Java, the `&&` and `||` operators provide for logical-and and logical-or. Both operators have _short-circuit evaluation_; they only evaluate the right-hand-side expression if the left-hand-side evaluates to `true` or `false`, respectively.

```

// with declared type
var a: bool = false && false; // == false
var b: bool = false && true;  // == false
var c: bool = true && false;  // == false
var d: bool = true && true;   // == true
// with inferred type
var e = false && false; // == false
var f = false && true;  // == false
var g = true && false;  // == false
var h = true && true;   // == true```

```

// with declared type
var a: bool = false || false; // == false
var b: bool = false || true;  // == true
var c: bool = true || false;  // == true
var d: bool = true || true;   // == true
// with inferred type
var e = false || false; // == false
var f = false || true;  // == true
var g = true || false;  // == true
var h = true || true;   // == true```

```

def doAnd() {
var a = print( 2) && print( 3); // == true  ; prints 2 3
var b = print( 4) && print(-6); // == false ; prints 4 -6
var c = print(-7) && print( 5); // == false ; prints -7
var d = print(-8) && print(-9); // == false ; prints -8
}
def doOr() {
var a = print( 2) || print( 3); // == true ; prints 2
var b = print( 4) || print(-6); // == true ; prints 4
var c = print(-7) || print( 5); // == true ; prints -7 5
var d = print(-8) || print(-9); // == false ; prints -8 -9
}
def print(x: int) -> bool {
System.puti(x);
System.puts("\n");
return x > 0;
}```