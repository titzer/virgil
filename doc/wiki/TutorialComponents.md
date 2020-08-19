# Top-level variables are private #

We've seen that we can declare variables and methods at the top-level in a file. However, all such variables and methods are private to that file. In order to share code across files, we must encapsulate those variables and methods in a named scope called a _component_.

Let's take a look at an example of a component with both code and data. As you can see, the `component` keyword declares a new component with the given name, and its contents are included in the curly braces { ... }.

```

// 'component' declares a scope for global data and functions
component FirstComponent {
var field1: int;      // a mutable field
def field2: int = 12; // an immutable field
def foo(a: int, b: int) -> int { // a method
return 2 * a + b;
}
}```

In the above example we define one of each the three kinds of members in a component: a mutable field, an immutable field, and a method. A component is public and can be used by other files in a program.

Below are more examples of components.

```

component ComponentField {
// 'var' declares a mutable field
var f: int;
var g: bool;
var h: byte = 'a';
}```

```

component ComponentValue {
// 'def' declares an immutable field or local
def f: int;
def g: bool;
def h: byte = 'a';
}
```

## Initialization ##

Virgil components are initialized at _compilation_ time rather than at startup time. The compiler contains an interpreter for the entire language and simply executes the code that you write to initialize variables and definitions before it generates a binary. The values assigned to variables and definitions are compiled directly into your executable.

```

component ComponentInit {
var a: byte = init();
def init() -> byte {
System.puts("Initializing.\n");
return 'a';
}
def main() {
System.puts("Running.\n");
}
}```

The program will print out `"Initializing."` during compilation:

<pre>
% virgil compile ComponentInit.v3<br>
Initializing.</pre>

The executable that is produced will print `"Running."`

<pre>
% ./ComponentInit<br>
Running.</pre>

And if we use the built-in interpreter for Virgil, it will first print `"Initializing."` and then `"Running."`

<pre>
% virgil ComponentInit.v3<br>
Initializing.<br>
Running.</pre>

This feature turns out to be useful in many situations where your program needs constants and data structures that are global to the program and used on every execution. It also allows the compiler more freedom in optimizing your program, since the initialization code is discarded after it has been run, and the compiler can optimize your program using the actual values of these variables that were computed during initialization.

## Scoping ##

By default all members of components are public and are accessible outside of the component by referencing the component's name using the member operator `.` to access the member. The `private` keyword can be used to limit the scope of a member to the enclosing component.

```

component ComponentPrivate {
// 'private' limits the scope of a member to this component
private var field1: int;
private def field2: int = 12;
private def twice(a: int) -> int {
return a + a;
}
// the default visibility is public
def foo(a: int, b: int) -> int {
return twice(field1) + field2;
}
}```

The code of these examples is available in the [starter zip](GettingStarted.md) as well as in the source repository under `virgil/doc/tutorial/Components`.