# Variance #

_Variance_ is a relation between subtyping rules for a type and subtyping rules for any types nested within the type. For example, if we have an object of type `List<Cat>`, is it safe to treat the object as a `List<Animal>`, since every `Cat` is an `Animal`? The question of variance arises for every kind of type that has nested types, including arrays, functions, tuples, and parameterized classes.

Virgil has a unique and simple approach to variance. Basically, the rules are:

  * Tuples are _covariant_ in their type parameters
  * Functions are _contravariant_ in their parameter type and _covariant_ in their return type
  * Arrays are _invariant_
  * User classes are _invariant_

We will explain covariance, contravariance, and invariance by way of examples for each of the rules below.

## Variant Tuples ##

Tuples are _covariantly_ typed. That means that `(Cat, Cat)` is a subtype of `(Animal, Animal)` and `(Cat, int)` is a subtype of `(Animal, int)`. It is easy to see that this is safe because tuples are immutable values, and clearly two cats are two animals, and a cat and an `int` are usable as an animal and an `int`.

## Variant Functions ##

The rule for variance of function types always looks somewhat bizarre and mysterious at first glance. Just remember that if we have a function `T -> Cat`, then since `Cat` is an `Animal`, the function can be used as a function of type `T -> Animal`. That's the covariant return type part of the rule. The other part of the rule is the opposite, i.e. contravariant. Suppose that a function has type `Animal -> T`. Since it accepts any kind of animal, then it can clearly be used in a context that passes only `Cat` instances, so it can be used in place of a function of type `Cat -> T`.

Tuples and functions work together nicely again here. Since variance rules are _inductive_, the variance rules for functions immediately extend to multiple arguments and multiple return values by way of covariance of tuples.

## Invariant arrays ##

Virgil arrays are _invariantly_ typed, meaning an `Array<Cat>` _is not_ a subtype of `Array<Animal>`, even though `Cat` is a subtype of `Animal`. This is because arrays are mutable. If arrays were not invariantly typed, then one could add `Animal` objects to an array of `Cat` by viewing the array of `Cat` as an array of `Animal` first. `*`

## Invariant classes ##

It is harder to see why Virgil user classes should also be invariant. After all, it is relatively easy to make an immutable `List` class that could safely be used in a _covariant_ way. The answer is that classes are invariant in Virgil simply because variance for function and tuple types mostly supplies the necessary reusability. Read on to see why.

## Uses of variance ##

Now we've seen the basic rules for variance. How do we use them? Let's go back to the `List<Cat>` and `List<Animal>` example. In Virgil, the two types are not related because `List` is a user-defined class, and all user-defined classes are invariant. It would not be legal to write a method that iterates over a `List<Animal>` and try to use it with a `List<Cat>`.

Given the rules for functions, it is, however, legal to write an apply method that does the job.

```

class List<T> {
def head: T;
def tail: List<T>;
new(head, tail) {}
}
class Animal {
}
class Cat extends Animal {
}
def apply<T>(list: List<T>, f: T -> void) {
for (l = list; l != null; l = l.tail) {
f(list.head);
}
}
def main() {
var animals: List<Animal>;
var cats: List<Cat>;
// because of variance, we can apply adopt to animals
apply(animals, adopt);
// and we can also apply it to cats!
apply<Cat>(cats, adopt);
}
def adopt(a: Animal) {
}```

## Future compatibility ##

It would be safe to have _immutable_, _covariantly_ typed arrays, since updates are not be allowed to immutable arrays. This is planned for an upcoming version of Virgil.

`*` Java famously allows unsafe covariance of arrays and dynamically checks all stores to arrays, throwing an exception for an invalid array store.