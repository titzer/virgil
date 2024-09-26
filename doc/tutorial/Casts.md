# Type Casts #

Virgil III is a statically-typed language where every variable and every value has a type. Sometimes it's necessary to cast a value from one type to another, while other situations may require testing the dynamic type of an object or value.

The rules for type casts and type queries in Virgil are some of the trickiest to master. Thankfully the Virgil compiler rejects nonsensical type casts and type queries wherever possible. Like other static checks in Virgil, this check reduces the chances you will make a mistake and therefore makes your programs more robust.

## Basic Syntax ##

Virgil uses the `!` operator for type casts and the `?` operator for type queries. When a cast is evaluated at runtime, it either produces a result of the expected type or terminates the program with a `!TypeCheckException`. A type query, however, always returns either `true` or `false`.

```
class Foo {
// an example class to show the syntax of casts
}
var a = Foo.new();
var x = Foo.!(a); // casts to Foo type
var y = Foo.?(a); // queries if a is a Foo
```

The operators are accessible as if they were type members. To cast an expression `e` _to_ a type `T`, write `T.!(e)` and to test whether the value `e` is of type `T`, write `T.?(e)`. The above example uses a class for the cast type, but the same applies to primitives and array casts.

## Primitives ##

Only casts between `byte` and `int` primitive types are allowed. A cast from `byte` to `int` performs a zero-extension just like a normal implicit conversion, and a cast from `int` to `byte` performs a truncation, preserving only the 8 lower bits of the value.

```
var a = 100; // example integer value
var b = '$'; // example byte value
var c = byte.!(a); // convert an int to a byte
var d = int.!(b);  // convert a byte to an int
```

Type queries for primitives, on the other hand, are never useful. A value of type `int` is never a value of type `bool` or any other type. The compiler rejects all casts between primitive types.

## Arrays ##

Array types are _invariant_, meaning that array types are not related to each other. Casts between different array types will always fail (except for the special case of a `null` array), so the compiler will reject them.

## Objects ##

Type casts and type queries are most useful when dealing with class types. Recall that each object remembers the class that created it. We can perform type queries and type casts on objects at runtime.

```
class Animal {
    // an example class to illustrate casts with objects
}
class Mammal extends Animal {
    // an example class to illustrate casts with objects
}
def main() {
    var x = Animal.new();
    var y = Mammal.new();
    for (e in [x, y]) {
        // dynamically query the type of each object
        if (Mammal.?(e)) System.puts("Mammal");
        else System.puts("Animal");
        System.puts("\n");
    }
}
```

The above example loops through an array of two different animals and checks which are mammals.

```
class Pet { // any kind of pet
}
class Cat extends Pet { // a cat
}
class Dog extends Pet { // a dog
}
def main() {
    // decide how to play with our pets
    var pets = [Cat.new(), Dog.new()];
    for (e in pets) {
        // dynamically check the type to decide how to play
        if (Cat.?(e)) playWithLaser(Cat.!(e));
        if (Dog.?(e)) playFetch(Dog.!(e));
    }
}
def playWithLaser(x: Cat) {
    // only we know how to use the laser, not the cat!
}
def playFetch(x: Dog) {
    // only we know how to throw the stick, not the dog!
}
```

The above example implements a method that plays with pets and illustrates how using type casts and type queries is sometimes the simplest approach. It would seem intrusive to add methods on each `Pet` corresponding to how we might play with it,  since only the `PetDemo` component really knows how to play with each kind of `Pet`. Instead of going overboard with a fancy _visitor pattern_, the cases are few enough that the straightforward approach with type casts and queries is probably simplest.

## Functions ##

Function types support casts that follow the rules of [variance](Variance.md).

## Rules for `null` ##

Objects, arrays, and function references can be `null`. At runtime a type cast of a `null` value will always succeed, but a type query of `null` will always evaluate to `false`.

## Tuples ##

Type casts and type queries on tuples are _inductive_. The result of typecasting a tuple value to another type is the result of individually casting each element value to the corresponding element type and creating a tuple from those values. If the element counts do not match, the cast fails. The result of a type query of a tuple value is `true` if and only if the result of querying every element value against its corresponding element type is `true`. Again, the compiler tries to reject invalid casts whenever possible at compile time.

## Cast and query operators are functions ##

Any type cast or type query can be used as a function as well. This allows us to pass them to other functions to implement some interesting patterns. For example, it is easy to implement an operation which searches an array for an object of a particular type:

```
class Person { // a demonstration class
}
class Employee extends Person { // our employees
}
def contains<T>(array: Array<T>, is: T -> bool) -> bool {
    // search any kind of array, using the is function.
    for (e in array) if (is(e)) return true;
    return false;
}
def main() {
    var people = [Person.new(), Person.new(), Employee.new()];
    // search the people array for an employee
    if (contains(people, Employee.?<Person>)) {
        System.puts("Employee found.\n");
    }
}
```

Here we check whether an object of type `Employee` exists in the array that contains objects of type `Person`. Notice that like the `?` operator of the `Employee` class that we pass here is given a _type argument_. This is because the `!` and `?` operators are like methods that have type parameters. You just didn't notice so far because those type arguments have been inferred!

## Cast and query operators have type parameters ##

We just saw that the type cast `!` and type query `?` operators are like methods that have type parameters. That means that just like other methods that have type parameters, we can _explicitly_ specify type arguments. The type argument that we supply is the _input type_ to the cast or query.

```
def main() {
    var z: bool, v: void;
    // illegal without explicit type argument
    var x = int.!<bool>(z); // cast bool -> int == runtime error
    var y = int.!<void>(v); // cast void -> int == runtime error
}
```

Explicitly specifying the type argument to a cast or query _disables_ the compiler's normal checks as to whether the cast is legal. The cast will _always_ be checked at runtime if we explicitly specify the type argument. The general rule is: if `T` and `F` are types, then `T.!<F>` is a function of type `F -> T` that performs a dynamic type cast operation, and `T.?<F>` is a function of type `F -> bool` that performs a dynamic query of the value against type `T`.

## Casts involving type parameters ##

Recall that type parameters are essentially a placeholder for an unknown type within the scope of their declaration. A type parameter could be instantiated with any type. For this reason, the Virgil compiler assumes that most casts involving type parameters _could_ succeed for _some_ type arguments, and therefore does not issue warnings. The casts and queries will be checked at runtime.

```
def print<T>(e: T) {
    // dynamically check whether the value is one of the supported types
    if (int.?(e)) return System.puti(int.!(e));
    if (byte.?(e)) return System.putc(byte.!(e));
    if (bool.?(e)) return System.puts(if(bool.!(e), "true", "false"));
    if (string.?(e)) return System.puts(string.!(e));
    System.error("PrintError", "Unknown type case");
}
def main() {
    // use the print method with different parameters
    print(0);
    print(" and then ");
    print('$');
    print(" also ");
    print(true);
    print(" bye.\n");
    print(()); // will cause a runtime error
}
```

The above example shows how to use casts involving type parameters to our advantage. Here, we define a parameterized `print` method that inspects its argument in order to determine how to handle it. If the argument is one of the types it supports, it casts the value to the appropriate type and displays it. Notice that with dynamic casts that there is always the possibility that we missed a case. Thus we trade the potential for a dynamic error for the localized ability to dynamically check the type of a parameter.

There are obviously some cases where the compiler can determine that a cast could _never_ work, such as attempting to cast a parameterized class to a primitive or array type. The compiler can detect and reject these cases whenever possible.

## Advice: avoid casts, usually ##

You should usually avoid type casts and type queries in your programs. A failed cast will terminate your program with an exception if it fails at runtime, therefore you should strive to make sure that no cast can ever fail. Type queries in your program may indicate that it has a design problem that could be avoided by restructuring your program.

However, sometimes type queries and type casts are the most straightforward and simplest way to solve a problem. If localized, they can serve as a cheap form of pattern matching, particularly when used with parameterized methods. You should consider the design impact of restructuring your program to avoid casts. If eliminating a few casts requires restructuring entire class hierarchies and adding lots of methods, then maybe it's not worth it; use your judgment for what is the simplest solution overall.
