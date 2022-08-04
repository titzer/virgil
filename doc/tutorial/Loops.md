# Loops #

Loops allow a program to repeatedly execute a block of code. Virgil supports looping with the `while`, `for`, and `for`-each loops. If you're familiar with C/C++ and Java, you can skip to the summary.

## While Loop ##

The `while` loop is the most basic kind of loop. It takes a condition expression of type `bool`. The condition is evaluated for each iteration of the loop; if `true`, then the body of the loop is executed. Otherwise, the loop terminates.

```
def main() {
    var a = 0;
    // execute the body repeatedly until the condition is false
    while(a < 2) {
        System.puts("hello ");
        a++;
    }
    System.puts("\n");
}
```

## Three-part `for` ##

Virgil supports a general three-part `for` loop, much like C, C++ and Java. Virgil differs in that none of the three clauses is optional.

```
def main(args: Array<string>) {
    for (i = 0; i < args.length; i++) {
        System.puts(args(i));
        System.puts("\n");
    }
}
```

In Virgil a `for` loop _always_ introduces a new iteration variable.
The three parts of the `for` loop are the _initialization_ which declares and initializes the iteration variable, the _condition_ which is evaluated at the start and at each iteration of the loop, and the _update_ which is executed at the end of each iteration.

## `for`-less-than shortened form for induction ##

Virgil supports another simplified version of the `for` loop that allows iteration from `0` to a limit, incrementing the iteration variable by `1` each iteration.
The type of the variable is the inferred to be the type of the limit expression.

```
def main(args: Array<string>) {
    for (i < 5) { // iterates over { 0, 1, 2, 3, 4 } in order
        System.puti(i);
        System.puts("\n");
    }
    // equivalent three-far for:
    for (i = 0; i < 5; i++) {
        System.puti(i);
        System.puts("\n");
    }
}
```

A `for`-less-than loop always introduces a new loop iteration variable that cannot be assigned in the loop body.

## `for`-in on arrays ##

Virgil supports a simplified version of the `for` loop that allows iteration over the elements of an array.
The keyword `in` to differentiates between the a three-part `for` and `for`-in.

```
def main(args: Array<string>) {
    for (e in args) {
        System.puts(e);
        System.puts("\n");
    }
}
```

A `for`-in loop always introduces a new loop variable that cannot be assigned in the loop body.

## `for`-in on an enum ##

The `for`-in loop form also allows iteration over the values in an enum.

```
enum State { OPEN, READING, CLOSED }

def main(args: Array<string>) {
    for (e in State) {
        System.puts(e.name);
        System.puts("\n");
    }
}
```

Like the other short forms, `for`-in over an enum always a new loop variable that cannot be assigned in the body.

## `break` and `continue` ##

Virgil supports the standard `break` and `continue` statements to either exit or repeat a loop from within its body.

```
def main() {
    var a = 0;
    while(a < 3) {
        System.puts("hello ");
        if (a == 2) break; // go to end of while loop
        a++;
    }
    System.puts("\n");
}
```

```
def main() {
    var a = 0;
    while(a < 3) {
        System.puts("hello ");
        if (a == 2) continue; // go back to start of while loop
        a++;
    }
    System.puts("\n");
}
```

Unlike C, C++, and Java, Virgil supports neither `goto` nor _labelled_ `break` or `continue` statements.
All `break` and `continue` statements refer to the innermost enclosing loop.

## Summary ##

Virgil inherits the basic `while` and `for` loops from C, while adding several shorter `for`-each and `for`-in forms.
No `goto`s are allowed and all `break` and `continue` statements refer to their nearest enclosing loop.
