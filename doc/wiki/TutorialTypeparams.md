# Type Parameters for Methods #

Type parameters are a powerful abstraction mechanism that allows you write methods that are independent of the actual type of data they manipulate, leading to more reusable code.

```

// search an array for a given element and return its index
def find<T>(a: Array<T>, x: T) -> int {
for (i = 0; i < a.length; i++) {
if (a(i) == x) return i;
}
return -1;
}```

When we declare a new method, we can specify one or more _type parameters_ in `< ... >` between the method name and the parameters list. In the above example, we write a `find` method that can search an array of any type for a given element. Within the scope of the `find` method we can use the type parameter `T` as if it were an actual type; in this case we use it as the element type of the array.

## Explicit Type Arguments ##

The `find` method we created in the previous example can be called with different types of arrays. Below we call it with an array of `int` and an array of `byte`.

```

// call with explicit type argument
var x = find<int>([1, 5, 8, 9], 7);
// call with explicit type argument
var y = find<byte>("the hello $", '$');
// search an array for a given element and return its index
def find<T>(a: Array<T>, x: T) -> int {
for (i = 0; i < a.length; i++) {
if (a(i) == x) return i;
}
return -1;
}```

Like method declarations and invocations, the syntax for passing type arguments mirrors the syntax for declaring type parameters. We simply call `find` with type arguments enclosed in `< ... >`.

## Implicit Type Arguments ##

Manually specifying the type arguments to every call isn't strictly necessary. Usually the compiler can _infer_ the type arguments from the surrounding context. Using type inference we can rewrite the above example to be more concise.

```

// call with inferred type argument
var x = find([1, 5, 8, 9], 7);
// call with inferred type argument
var y = find("the hello $", '$');
// search an array for a given element and return its index
def find<T>(a: Array<T>, x: T) -> int {
for (i = 0; i < a.length; i++) {
if (a(i) == x) return i;
}
return -1;
}```

## Type Parameters are Separately Typechecked ##

A type parameter is like a placeholder for a type, introducing a new name within the scope of the method. The compiler checks the body of the method as if the type was completely unknown and not related to any other type except itself. That means that when a parameterized method typechecks successfully, it is guaranteed to work with _any_ type. Type errors in the body of the method do not affect usage sites and vice versa.

## Type Parameters are Universal ##

A key idea in Virgil is that _any type_ can be substituted for a type parameter at a usage site. In the `find` examples, we saw both `byte` and `int`, but we could easily have substituted any other type, including tuple types, function types, and even `void`. No exceptions!

## Type Parameters and Functions ##

Type parameters and functions mix naturally. For example, it is common to define a parameterized method that also takes a function that operates on the parameterized type. Below, we use this concept to write a `map` utility function that creates a new array from an existing array where the elements of the new array are the result of applying the supplied function to each element of the input array.

```

// with explicit type arguments
var y = map<int, bool>([1, 3, -4, 2], isPositive);
// with inferred type arguments
var w = map([1, 3, -4, 2], isPositive);

def map<A, B>(array: Array<A>, func: A -> B) -> Array<B> {
if (array == null) return null;
var max = array.length, r = Array<B>.new(max);
for (i = 0; i < max; i++) r(i) = func(array(i));
return r;
}
def isPositive(a: int) -> bool {
return a > 0;
}```

Notice that in the body of the `map` method, we can create an array with element type `B`. This works even with primitives or any other type! `*`

## Tuples, Functions, and Type Parameters ##

We've seen that tuples and functions work together [well](TutorialFunctions.md), and here we've seen that functions and type parameters work together well. Surprisingly, thanks to the universal nature of type parameters, all three features work together nicely as well. For example, we can use all three features to write a `time` utility that can be applied to _any_ function with _any_ parameters and returns both the elapsed microseconds and the result of the function. `*`

```

var x: (int, int) = time(square, 5);  // int -> int
var y: (int, int) = time(cube, 5);    // int -> int
var z: (int, void) = time(nloop, (0, 100)); // (int, int) -> void

// measures microseconds elapsed to evaluate func(a)
// and returns both the time and the result
def time<A, B>(func: A -> B, a: A) -> (int, B) {
var before = System.ticksUs();
var r = func(a);
return (System.ticksUs() - before, r);
}
def square(n: int) -> int {
return n * n;
}
def cube(n: int) -> int {
return n * n * n;
}
def nloop(min: int, max: int) {
for (i = min; i < max; i++) ;
}```

`*` You can't do either of those things in Java or Scala. Ha!