# Classes and Functions #

Virgil integrates classes and functions in a seamless way by allowing any method of any class or object to be used as a function.

## Class Methods ##

We can use methods from a class as functions simply by referring to them with the `ClassName.methodName` syntax. Recall that classes can be instantiated to objects and that each method in a class accepts a `this` parameter that is bound to the receiver object of a method call. In much the same way, a _class method_ accepts the receiver object as its first parameter.

```

// a class to demonstrate class methods
class ClassMethods(f: int) {
def add(a: int) -> int {
return a + f;
}
}
var o = ClassMethods.new(3);
// "Class.method" can be used as a first class function
var m: (ClassMethods, int) -> int = ClassMethods.add;
// the function accepts the receiver object as the first parameter
var x = m(o, 2);```

The basic rule is that for any class `C` that has a method `m` with declared parameter types `P1` ... `Pn` and return type `R`, then `C.m` refers to a function of type `(C, P1 ... Pn) -> R`. More informally, you can just use any function from a class and it expects the object as its first parameter!

## Object Methods ##

Class methods allow us to use methods from a class without needing an instance. We can also use methods that are _bound_ to an object simply by referring to the method but _without passing arguments_.

```

// a class to demonstrate object methods
class ObjectMethods(f: int) {
def add(a: int) -> int {
return a + f;
}
}
var o = ObjectMethods.new(3);
// "obj.method" can be used as a first class function
var m: int -> int = o.add;
// the function is bound to the object from which it came
var x = m(2);```

The general rule is that if `e` is an expression of type `C` and `m` is a method in class `C` of type `P -> R` then `e.m` is a function of type `P -> R` that is _bound_ to the object referenced by `e`. More informally, an object method is a function that "remembers" the object from which it was created and accepts the same parameter types that the object's method accepts.

## Constructor Function ##

We can use the constructor of a class as a function, just like we did with class methods, just by referring to it by the `ClassName.new` syntax. In fact, its exactly the same as just using the constructor but _without passing arguments_.

```

// a class to demonstrate using the constructor as a function
class ClassNewFunction {
new(a: int) {
System.puti(a);
System.puts("\n");
}
}
// we can use the constructor as a first class function
var f: int -> ClassNewFunction = ClassNewFunction.new;
// and we can apply the function to create a new object
var o: ClassNewFunction = f(3);```

## Class fields ##

In addition to using a class method as a first class function, we can use a _class field_ as a first class function. The syntax is simply `ClassName.fieldName`. The function takes a receiver object as the first parameter and returns the value of the corresponding field.

```

// a class to demonstrate class fields
class ClassFields {
def f: int = 13;
}
var o = ClassFields.new();
// "Class.field" can be used as a first class function
var m: ClassFields -> int = ClassFields.f;
// the function reads the field from the passed object
var x = m(o);```

## Putting it all together ##

Using functions and classes together provides for some powerful reuse opportunities. For example, we could use the `map` function that we previously defined, together with class methods, to easily transform an array of objects into another array that contains the result of some operation on those objects.

```

// a class to demonstrate the use of Class methods in MapArray.map
class ClassMap(x: int) {
def get() -> int {
return x;
}
}
// an array of ClassMap objects
var a = [ClassMap.new(2), ClassMap.new(3), ClassMap.new(11)];
// create an array containing the result of .get() on each object in a
var x = map(a, ClassMap.get);

// standard array map utility
def map<A, B>(array: Array<A>, func: A -> B) -> Array<B> {
if (array == null) return null;
var max = array.length, r = Array<B>.new(max);
for (i = 0; i < max; i++) r(i) = func(array(i));
return r;
}```

## Virtual dispatch ##

Class methods and object methods always perform virtual dispatch when used as first-class functions, just as one would expect.

```

class FunctionVirtualA {
def name() -> string {
return "A";
}
}
class FunctionVirtualB extends FunctionVirtualA {
def name() -> string {
return "B";
}
}
var a = FunctionVirtualA.new();
var b = FunctionVirtualB.new();
var na = apply(FunctionVirtualA.name, a); // == "A"
var nb = apply(FunctionVirtualA.name, b); // == "B"

def apply(f: FunctionVirtualA -> string, o: FunctionVirtualA) -> string {
return f(o);
}```