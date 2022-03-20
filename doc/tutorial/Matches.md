# Match Statements #

Virgil III supports switch statements with the `match` keyword. Match statements simplify conditional patterns that would otherwise result in a long chain of `if` statements.

```
def main(a: Array<string>) -> int {
    var x: int;
    // match an integer value
    match (a.length) {
        0 => x = 9;
        // cases do not fall through
        1 => x = 5;
        // cases do not fall through
        2 => x = 7;
    }
    return x;
}
```

In Virgil, the values of each case are each specified with a following arrow `=>`, and then the statement for the value. Notice also that cases of a `match` statement _never_ fall through.


## Multiple case values ##

Multiple values for a single case can be specified by separating them with commas `,`.

```
def main(a: Array<string>) -> int {
    match (a.length) {
        // multiple values for a single case
        0, 1, 2, 3 => return 11;
        4, 5, 6, 7 => return 12;
    }
    return -1;
}
```

## Else clause or `_` case ##

Virgil allows two options for specifying the default case. One is an optional `else` clause, much like an `if`.

```
def main(a: Array<string>) -> int {
    match (a.length) {
        0 => return 11;
        1 => return 12;
    } else {
        // 'else' defines a default case for a match statement
        // similar to an if statement
        return 13;
    }
}
```

The other option is to use the underscore expression `_` to specify a default case.

```
def main(a: Array<string>) -> int {
    match (a.length) {
        0 => return 11;
        1 => return 12;
        _ => return 13; // default case
    }
}
```

Because the cases are statements, we can also use blocks.

```
def main(a: Array<string>) -> int {
    match (a.length) {
        0 => {
            // a case can be a block of code
            System.puts("zero\n");
            return 11;
        }
        1 => {
            // remember, cases do not fall through
            System.puts("one\n");
            return 12;
        }
    }
}
```


## Symbolic constants ##

Virgil allows both literal constants and component definitions of literals as the case values.

```
def ONE = 1;
def TWO = 2;
def main(a: Array<string>) -> int {
    // immutable component fields can be used for match case values
    // if those fields are initialized with a literal
    match (a.length) {
        ONE => return 11;
        TWO => return 12;
    }
    return -1;
}
```

## Matching on types ##

Virgil allows match statements to match on the types of values. We use a syntax that allows us to bind a local variable, allowing the code in the case statement to refer to the value through a name that has the right type.

```
class A { }
class B(foo: int) extends A { }
class C(bar: int) extends A { }
def do(a: A) -> int {
    match (a) {
        x: B => return x.foo; // x is of type B
        x: C => return x.bar; // x is of type C
        x: A => return 33;    // x is of type A
    }
    return -1; // can happen with null
}
```

## Matching on ADTs ##

Virgil allows match statements to pattern-match on values of an abstract datatype. We use a syntax that mirrors the declaration of the ADT and allows us to bind to the parameters of each case of the ADT. Match statements on ADTs are checked to be exhaustive: i.e. they must cover every case of the ADT, even if just by defining a default case.

```
type A {
    case B(foo: int);
    case C(bar: int);
}
def do(a: A) -> int {
    match (a) {
        B(foo) => return foo; // match and bind params of a B
        C(bar) => return bar; // match and bind params of a C
    }  // match must be exhaustive
    // unreachable, because all cases return
}
```

## Future Features ##

More powerful pattern-matching is always being considered, including matching over part of the value of a tuple, integer value ranges, the fields of an object, etc.
