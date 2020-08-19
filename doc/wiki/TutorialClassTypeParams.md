# Type Parameters for Classes #

Like methods, classes can be _abstracted_ over types by introducing type parameters. The syntax for declaring type parameters mirrors that for parameterizing methods; we simply follow the name of the class we are declaring with one or more type parameters in `< ... >` brackets.

```

// A basic cons list
class List<T>(head: T, tail: List<T>) {
}
// creates a simple one-element list
var a = List<int>.new(0, null);
// create a new list linked to the previous list
var b = List<int>.new(1, a);
// create a list of a single string
var c = List<string>.new("hello", null);```

The example above demonstrates building a simple immutable list using a class. The type parameter `T` abstracts the type of the elements stored in the list. As with using parameterized methods, when we refer to the `List` class, we can explicitly specify the type argument.

## Type inference ##

Like type arguments for methods, the compiler can sometimes infer the type arguments to a parameterized class.

```

// A basic cons list
class List<T>(head: T, tail: List<T>) {
}
// creates a simple one-element list
var a = List.new(0, null);
// create a new list linked to the previous list
var b = List.new(1, a);
// create a list of a single string
var c = List.new("hello", null);```

In general, the compiler can only infer the type arguments to classes if there is enough surrounding context to make it clear. In practice that means that most class type arguments need to be explicit.

## Composability ##

Just like type parameters for methods, type parameters for classes can be instantiated with _any_ type. That means that our `List` example class could be instantiated with any primitive type, `void`, arrays, classes, tuples, or even function types. No exceptions!

## Functions are fully supported ##

There are no restrictions on using class or object methods from parameterized classes. The syntax allows specifying the type arguments to the class type or method type as necessary.

```

// a sketch of a growable array class
class Vector<T> {
var length: int;
def add(e: T) {
// adds the element to this vector
}
def apply<R>(f: T -> R) {
// applies the given function to every element in this array
}
}
def copy<T>(a: Vector<T>, b: Vector<T>) {
// pass b.add to a.apply to copy a's contents into b!
a.apply(b.add);
}```

The above example illustrates the power of reuse that combining type parameters, functions, and classes provide. We can define a generic `copy` method that copies the contents of one `Vector` instance to the other. To accomplish this in a single line of _statically typed_ code, we can simply pass the `add` method bound to the destination `Vector` to the `apply` method of the source vector!

## Type Parameters and Inheritance ##

Classes do not "inherit" type parameters from their parent class as they do members like fields and methods. Instead, a class that extends a parameterized super class must specify the type arguments of its super class in its `extends` clause.

```

// parameterized superclass demo
class ClassExtendsSuper<T> {
def id(x: T) -> T {
return x;
}
}
// the subclass must explicitly pass type arguments to its super class
class ClassExtendsTypeArg<E> extends ClassExtendsSuper<E> {
def id2(x: E, y: E) -> (E, E) {
return (id(x), id(y));
}
}```

In this example, the subclass must specify explicit type arguments to its super class in the `extends` class. It does not, however, have access to the `T` type parameter of its super class, because that type only exists within the scope of the super class. Instead, the type `E` exists in the scope of the subclass. The `id` method inherited from the super class has type `E -> E` when used in the subclass, not `T -> T`. In essence, the subclass extends a _specialized_ version of the superclass where all the `T`'s have been replaced with `E`.