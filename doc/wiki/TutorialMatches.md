# Match Statements #

Virgil III supports switch statements with the `match` keyword. Match statements simplify conditional patterns that would otherwise result in a long chain of `if` statements.

```

def main(a: Array<string>) -> int {
var x: int;
// match an integer value
match (a.length) {
0: x = 9;
// cases do not fall through
1: x = 5;
// cases do not fall through
2: x = 7;
}
return x;
}```

In Virgil, the values of each case are each specified with a following colon `:`, and then the statement for the value. Notice also that cases of a `match` statement _never_ fall through.


## Multiple case values ##

Multiple values for a single case can be specified by separating them with commas `,`.

```

def main(a: Array<string>) -> int {
match (a.length) {
// multiple values for a single case
0, 1, 2, 3: return 11;
4, 5, 6, 7: return 12;
}
return -1;
}```

## Else clause ##

Instead of a special _default_ case, the `match` statement allows an optional `else` clause, much like an `if`.

```

def main(a: Array<string>) -> int {
match (a.length) {
0: return 11;
1: return 12;
} else {
// 'else' defines a default case for a match statement
// similar to an if statement
return 13;
}
}```

We can also use blocks as the case statements.

```

def main(a: Array<string>) -> int {
match (a.length) {
0: {
// a case can be a block of code
System.puts("zero\n");
return 11;
}
1: {
// remember, cases do not fall through
System.puts("one\n");
return 12;
}
} else {
return 13;
}
}```


## Symbolic constants ##

Virgil allows both literal constants and component definitions of literals as the case values.

```

def ONE = 1;
def TWO = 2;
def main(a: Array<string>) -> int {
// immutable component fields can be used for match case values
// if those fields are initialized with a literal
match (a.length) {
ONE: return 11;
TWO: return 12;
}
return -1;
}```

## Future Compatibility ##

More powerful pattern-matching is being considered for future versions of Virgil, including matching over part of the value of a tuple, integer value ranges, the fields of an object, or the type of the value.