# Partial Application #

As we've seen, Virgil offers a lot of flexibility for writing code in a functional style. Any method and most of the basic operators can be used as first-class functions. This allows for a lot of fine-grained reuse.

Virgil also allows any function to be _partially applied_, meaning that a call of the function can have one or more of the arguments simply _left out_. The expression evaluates to a _new function_ that remembers the arguments that weren't left out and accepts the parameters that were left out.

Let's look at a simple example:

```

// Demonstrates partial application of a two-parameter function
def main() {
// a function which has "Hello " bound to its first parameter
var hello = print2("Hello ", _);
// call it, supplying the missing parameter
hello("Alice");
hello("Bob");
hello("Fred");
}
def print2(a: string, b: string) {
System.puts(a);
System.puts(b);
System.ln();
}```

In the above code, we create a partially applied function called `hello` by writing what looks like a call to the `print2` method, but with a hole in the form of an underscore (`_`). The underscore takes the place of the unknown parameter. The result of this (partial) call is a new function which remembers the bound arguments but accepts the unknown parameter. We can then call this new function, supplying the missing parameters.

```

// Demonstrates partial application of primitive operators
def main() {
var inc = int.+(1, _); // a function that adds 1 to its parameter
for (i = 0; i < 10; i = inc(i)) {
System.puti(i);
System.ln();
}
}```

The above code demonstrates that we can do the same thing with any function, including a primitive operator. (that's cool!)

```

// A representation of a person's information
class Person {
def name: string;
var age: int;
var employer: string;
var manager: Person;
var alive: bool;
new(name, age, employer, manager, alive) {}
}
// demonstrates use of partial application to reduce redundancy in construction
def main() {
// create Larry, the CEO
var page = Person.new("Larry Page", 39, "Google", null, true);
// a function to make Googlers (who default to Larry)
var googler = Person.new(_, _, "Google", page, true);

// some Googlers
var susan = googler("Susan", 27);
var ken = googler("Ken", 37);
var thomas = googler("Thomas", 30);

// a function to create a bunch of deceased people
var dead = Person.new(_, 0, "", null, false);

var bob = dead("Bob");
var kelly = dead("Kelly");

// print all our persons
for (p in [page, susan, ken, thomas, bob, kelly]) print(p);
}
def print(p: Person) {
// print a person
System.puts(p.name);
System.puts(" ");
System.puti(p.age);
System.puts(" ");
if (p.alive) {
System.puts(p.employer);
System.puts(" ");
System.puts(if(p.manager != null, p.manager.name, ""));
} else {
System.puts("[deceased]");
}
System.ln();
}```

In the final example, we can see how powerful this mechanism can be to factor out a lot of common code. Here, we create a little function for making `Person` objects that represent Google employees. We can do this simply by using the constructor of the `Person` class, but binding some of the arguments to appropriate defaults for Googlers.