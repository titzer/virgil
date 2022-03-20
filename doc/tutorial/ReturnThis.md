# Returning `this` #

Virgil has a unique, innovative shorthand for methods of an object that return the `this` argument.
A method whose return type is declared as `this` implicitly returns the object that was passed as the receiver.
This shorthand allows us to express many convenient patterns such as builders.

## Methods ##

To use this feature, we simply write `this` as the return type and the compiler will insert an implicit return at exactly the right spots.

```
class Accumulator {
    var total: int;
    def add(x: int) -> this {
        total += x;
	// implicit return inserted
    }
}

var a = Accmulator.new();
var x = a.add(3).add(4).add(5);
```

## No loss of intermediate type information ##

There is another benefit from this feature, besides simple terseness.
When we invoke a method that is declared to return `this`, the compiler doesn't "forget" the type of the object which was called, so we can extend a class and add more methods, without losing access to them when we call one of the super methods.

```
class A {
    var total: int;
    def add(x: int) -> this {
        total += x;
    }
}
class B extends A {
    def mul(x: int) -> this {
        total *= x;
    }
}

var b = B.new();
// all subexpressions are of type {B}, even though {add} is declared in {A}
var x = a.add(3).mul(4).add(5);
```

## Used in standard libraries ##

Because of the convenience of this feature, it is used extensively in the standard library classes such as `StringBuilder`.
This allows for nice chaining of method calls that keeps your code short, even if you extend these classes with your own new functionality!

```
var str1 = StringBuilder.new().put1("the value is %d", 889).toString();

var str2 = StringBuilder.new()
    .put1("the value is %d", 889)
    .put1(", except when it is %d", 887)
    .toString();

class MyStringBuilder extends StringBuilder {
    def putm(m: MyClass) -> this { ... }
}

var str3 = MyStringBuilder.new()
    .put1("the value is %d, and by the way, ", 889)
    .putm(MyClass.new())
    .toString();
```
