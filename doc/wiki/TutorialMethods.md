# Methods #

Methods are the fundamental building block of Virgil III code. Just as with variables, a method is declared within a _scope_, such as a file, a  [class](TutorialClasses.md) or [component](TutorialComponents.md). We've already seen the definition of a _main_ method for a program. Let's look at another method.

```

// recursive computation of fibonacci sequence
def fib(i: int) -> int {
if (i <= 1) return 1; // base case
return fib(i - 1) + fib(i - 2); // recursive calls
}```

This example declares a `fib` method using the `def` keyword. In this case the `fib` method takes a single parameter of type `int` and computes the requested Fibonacci number by adding the result of two recursive calls.

## Parameters ##

A method can have zero or more parameters that are declared in parentheses `( ... )` following the name. The syntax for parameters is like Pascal. We first write the parameter name, then a colon `:`, followed by its type. Similar to declaring variables, the colon serves as a visual cue that a type follows. However, unlike variables, we must always specify the type of a parameter to a method.

```

def first() {
second(112);
}
def second(a: int) {
var x: int = a;
third(x, false);
}
def third(a: int, b: bool) {
fourth(a, b);
}
def fourth(a: (int, bool)) {
var x = a.0;
var y = a.1;
}```

## Return Type ##

Methods can have an optional return type. To specify a return type, we simply follow the parameters with an arrow `->` and then the return type. If a method has no declared return type, then it implicitly returns `void`.

```

def first() {
return; // return of void
}
def second() -> int {
return 13; // return of value
}
def third() -> bool {
return false;
}```

## Calls ##

As we can see from the above examples, calls to methods have the usual syntax. We simply write its name, followed by the arguments in parentheses `( ... )`, separated by commas. The argument expressions are evaluated in left-to-right order and then the method is invoked.

## Void ##

Recall that `void` is just like any other type in Virgil. When it comes to methods, `void` can legally appear as the parameter type or return type of a method, and we can explicitly return the `void` value `()` from within the body of the return. Thus, the statement `return;` is simply shorthand for `return ();`.

```

def first() { // implicitly returns void
second();
}
def second() -> void { // explicitly returns void
return third();
}
def third(v: void) { // explicitly takes void
fourth();
return;
}
def fourth(v: void) -> void {
return ();
}```

Better yet, `void` is so uniformly treated that we can actually _chain_ the invocations of `void` methods together in arbitrary ways.

```

def first() {
return second(); // second() returns void
}
def second() {
third(fourth()); // fourth() returns void and third() accepts void
return System.puts("Second"); // puts() returns void
}
def third() {
if (true) return fourth();
else return fifth();
}
def fourth() {
// ...
}
def fifth() {
// ...
}```

Why is chaining in this way useful? It turns out that it works really well with [type parameters](TutorialTypeparams.md). Returning the implicit `void` result of another call can often save a line of code, for example, by shortening a branch to a single line, like in the example of the `third` method above.