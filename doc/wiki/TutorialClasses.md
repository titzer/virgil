# Classes #

Virgil III supports object-oriented programming with classes which serve to encapsulate mutable and immutable state and group related functionality. Classes can be used to instantiate new objects which form the basis of most data structures you will build in Virgil.

## Fields ##

Classes can contain mutable variables and immutable variables, which we refer to as _fields_.

```

class Example1 {
var a: int;     // mutable field declaration
def b: int = 3; // immutable field declaration
}```

Once again, we use the `var` keyword to declare mutable fields and the `def` keyword to declare immutable fields.

## Methods ##

Classes can contain methods as well. We always use the `def` keyword to declare these methods inside the body of the class.

```

class Example2 {
var a: int;
var b: int;
def add(x: int) -> int {
return a + b + x;
}
}```

The fields declared in the class are in scope for each method, allowing them to be used in the method body.

## Creation ##

Unlike components which have a single instance for the entire program, classes are used to create objects by calling a special `new` method that creates a new instance of the class.

```

class Example3 {
var a: int;
var b: int;
}
// create a new object of type Example3 by calling .new()
var x = Example3.new();
// create a second instance of the same class
var y = Example3.new();```

Each object has distinct storage for its fields, so that updates to the mutable fields of one object do not affect the values of fields of another object.

## Constructor ##

Classes can have a _constructor_ method which defines how to initialize an object of the class from parameters. A constructor method is distinguished from other methods by using the keyword `new`.

```

class Example4 {
var a: int;
var b: int;
new(x: int) {
a = x + 1;
b = x + 2;
}
}
// create a new object of type Example4 by calling .new()
var object = Example4.new(100);```

In this example, the class's constructor accepts a single integer and initializes the two fields based on that integer. At the creation site we must therefore pass an integer argument when calling `new` for that class.

## The `this` parameter ##

Methods and constructors have an implicit parameter called `this` that refers to the instance of the object upon which the method was invoked.

```

class Example5 {
var x: int;
new() {
// "this" refers to the object being initialized
this.x = 11;
}
def m() -> int {
// "this" refers to receiver object for this call
return this.x;
}
}```

The `this` parameter does not exist within the scope of initialization expressions, since the `this` object is not fully constructed.

## Member Access ##

Once we've instantiated objects, we can access their fields and methods by using the `.` member operator.

```

class Example6 {
var a: int = 3;
def m(x: int) -> int {
return x + a;
}
}
def main() {
var obj = Example6.new();
var y = obj.a;     // field read
obj.a = 4;         // field write
var z = obj.m(10); // method call
System.puti(z);
System.puts("\n");
}```

## Objects are references ##

Objects are always allocated on the heap and always passed by reference. Therefore any updates on a dynamic instance of an object are visible to holders of a reference to that object.

## Implicit field initialization ##

Virgil supports a convenient shorthand for initialization fields of classes. If a constructor parameter matches the name of a field _exactly_, then the field is implicitly assigned the value of the parameter before any other initialization code executes. It is also possible to omit the type of the constructor parameter in this case.

```

class Example7 {
var a: int; // mutable
def b: int; // immutable
new(a, b) {
// constructor params that match fields introduce implicit
// initialization of matching fields
}
def print() {
System.puts("Example7{a=");
System.puti(a);
System.puts(", b=");
System.puti(b);
System.puts("}\n");
}
}
def main() {
var obj = Example7.new(3, 5);
obj.print();
obj.a = 7;
obj.print();
}```

## Initialization order ##

Virgil has a strict initialization order that is enforced at compile time in order to prevent partially constructed objects from escaping into the rest of the program.

  * Implicit field initializations from constructor parameters (left to right)
  * Explicit field initializations in field declarations (top to bottom)
  * Constructor body

Accesses of uninitialized fields are disallowed by checking that each field's initialization expression only references fields declared before it or declared as implicitly initialized by constructor parameters. Similarly, the `this` parameter does not exist in the scope of field initializations. This ensures that once the constructor body begins executing, all fields with an initializer, implicit or explicit, have been initialized. All other fields are implicitly initialized with the default value before the constructor body executes.

## Method Type Parameters ##

Just like methods outside of classes, methods inside of classes can have [type parameters](TutorialTypeparams.md). The syntax is exactly the same, and usage of parameterized class methods is similar to that for parameterized component methods.

```

class Searcher {
def ints = [0, 1, 2];
def bytes = ['0', '1', '2'];
// search for an integer in the ints array
def hasInt(x: int) -> bool {
return find(ints, x) >= 0;
}
// search for a byte in the bytes array
def hasByte(x: byte) -> bool {
return find(bytes, x) >= 0;
}
// search an array for a given element and return its index
def find<T>(a: Array<T>, x: T) -> int {
for (i = 0; i < a.length; i++) {
if (a(i) == x) return i;
}
return -1;
}
}```

## Visibility ##

The `private` keyword limits the scope of class members to the enclosing class. Members that are declared `private` are not visible from outside the class.

```

class Example8 {
var x: int;
// private fields are only visible from within the class
private var y: int = 11;
// private methods are only visible from within the class
private def m() -> int {
return y;
}
}```

## No static members ##

Unlike C++, C#, and Java, Virgil classes _do not_ have static members. All members of a class in Virgil are instance members, preventing the jumbling of global state and per-object state that can lead to confusion in other languages. Instead, use components to encapsulate methods and fields that would be static in these other languages.