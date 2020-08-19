# Reducing syntactic overhead for small classes #

Many small classes have some number of public, immutable fields and a collection of related methods. _Class parameters_ reduce the amount of boilerplate needed to declare such classes.

```

// Without class parameters:
// explicit field declarations and constructor
class IntPairExplicit {
def a: int;
def b: int;
new(a, b) { }
def sum() -> int {
return a + b;
}
}
// With class parameters:
// implicit field declarations and constructor
class IntPair(a: int, b: int) {
def sum() -> int {
return a + b;
}
}

// both classes have a constructor that accepts two ints
def x = IntPairExplicit.new(4, 5);
def y = IntPair.new(4, 5);```

Above we can see that class parameters allow us to avoid the redundancy inherent in declaring fields and then repeating the fields _again_ in a constructor declaration. The fields can simply be declared as part of the class, like method parameters. The constructor is then implicitly created for you.

## Extra construction ##

Sometimes a class might principally feature a number of public, immutable fields, but have some nontrivial constructor work to do. In this case, Virgil supports an extra constructor that allows the class to perform more work after the initialization of the implicit fields.

```

// Extra constructor work can be done with an explicit constructor
class SquareRange(start: int, end: int) {
def squares = Array<int>.new(end - start);
new() {
for (i = 0; i < squares.length; i++) {
squares(i) = (start + i) * (start + i);
}
}
}
// compute the squares of all numbers between 0 and 33
def x = SquareRange.new(0, 33);```

## Inheritance and class parameters ##

Class parameters also support inheritance. In particular, there are several choices to allow you to specify how a class's constructor calls its super constructor.

```

// With class parameters:
// implicit field declarations and constructor
class IntPair(a: int, b: int) {
def sum() -> int {
return a + b;
}
}
// Alternative A:
// explicit constructor and call to super
class IntTripleA extends IntPair {
def c: int;
new(a: int, b: int, c) super(a, b) { }
def sum() -> int {
return a + b + c;
}
}
// Alternative B:
// class parameters, explicit constructor and call to super
class IntTripleB(x: int, y: int, c: int) extends IntPair {
new() super(x, y) { }
def sum() -> int {
return a + b + c;
}
}
// Alternative C:
// class parameters, implicit constructor and call to super
class IntTripleC(x: int, y: int, c: int) extends IntPair(x, y) {
def sum() -> int {
return a + b + c;
}
}

// all alternatives have a constructor that accepts 3 ints
def x = IntTripleA.new(1, 2, 3);
def y = IntTripleB.new(1, 2, 3);
def z = IntTripleC.new(1, 2, 3);```