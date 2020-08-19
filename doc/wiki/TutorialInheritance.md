# Inheritance #

Virgil supports inheritance between classes which allows one class to _inherit_ the public fields and methods of another class, _extend_ the class by adding additional fields and methods, and _override_ the definitions of methods in the super class.

## Inheriting fields ##

```

class InheritFieldA {
var a: int = 65;
var b: int = 77;
}
class InheritFieldB extends InheritFieldA {
def sum() -> int {
// a and b are inherited from the super class
return a + b;
}
}
```

In this example, the `InheritFieldB` class uses the `extends` keyword to specify its super class. It inherits the public fields from the `InheritFieldA` super class and uses them in the definition of a new class.

## Extending classes with new methods ##

Virgil uses the keyword `extends` in the same way as Java. It makes clear that the new class can declare _more_ functionality by adding new fields and methods.

```

class InheritMethodA {
var a: int;
var b: int;
def sum() -> int {
return a + b;
}
}
class InheritMethodB extends InheritMethodA {
// extend the parent class with a new method
def sumSquared() -> int {
// the sum() method is inherited from the parent class
return sum() * sum();
}
}```

## Overriding methods ##

Virgil classes can do more than simply add fields and methods when they extend a super class; they can also _override_ the implementation of a method with a new implementation.

```

class OverrideMethodA {
var a: int;
var b: int;
def sum() -> int {
return a + b;
}
}
class OverrideMethodB extends OverrideMethodA {
var c: int;
// overrides the sum() def from the parent class
def sum() -> int {
return a + b + c;
}
}```

In the example above, the subclass `OverrideMethodB` extends the super class `OverrideMethodA` by adding a field and overrides the definition of the `sum` method with a new implementation that sums over all three fields. A method in a subclass overrides a method in a superclass if it has the same name. The compiler checks that the new method's parameter and return types match those of the superclass.

## Super clause ##

When extending a class that has a constructor, a new class must also have a constructor and specify how the super class's constructor is called from the subclass constructor. We do this by inserting a call to the superclass's constructor _between_ the constructor declaration and its body and use the keyword `super`.

```

class NewSuperA {
def a: int;
new(a) { }
}
class NewSuperB extends NewSuperA {
def b: int;
// use 'super' to explicitly call the super constructor
// before the body of the constructor executes
new(x: int, b) super(x) { }
}```


## Subtyping ##

When a Virgil class extends another class, the new class not only inherits the functionality of the super class but also becomes a _subtype_ of the super class. Objects of the new class can be used anywhere objects of the super class are expected.

```

class SubtypeA {
var a: int;
var b: int;
}
class SubtypeB extends SubtypeA {
var c: int;
}
// OK because B is a subtype of A
var x: SubtypeA = SubtypeB.new();
// OK because B is a subtype of A
var y: Array<SubtypeA> = [SubtypeB.new(), SubtypeA.new()];
// OK because B is a subtype of A
var z = sum(SubtypeB.new());

def sum(o: SubtypeA) -> int {
return o.a + o.b;
}```

## Methods are virtual ##

All method calls on Virgil objects are _virtual_, meaning that a call will always invoke the version of the method associated with the object's dynamic type at runtime. An object always "remembers" the class it was constructed from, even if the object is passed to a place in the program that accepts references of its super class. To improve efficiency, the compiler uses several analyses to determine which version of the method may be invoked at each call site, replacing method lookups with direct calls whenever possible.

```

class VirtualMethodA {
def name() -> string {
return "A";
}
}
class VirtualMethodB extends VirtualMethodA {
// overrides name()
def name() -> string {
return "B";
}
}
var a = VirtualMethodA.new();
var b = VirtualMethodB.new();
var x = a.name(); // calls A.name() because a is of type A
var y = b.name(); // calls B.name() because b is of type B

def name(o: VirtualMethodA) -> string {
return o.name(); // calls A.name() or B.name() depending on the object
}```

## Initialization order ##

Recall that classes have a careful [initialization order](TutorialClasses.md) where the field initializers are executed before the body of the constructor. For classes that have a super class, these field initializations happen before the call to the super constructor.

The overall execution order of initialization is therefore:

  * Implicit field initializations (left to right)
  * Explicit field initializations (top to bottom)
  * Call to super constructor
  * Constructor body

This is somewhat backwards to Java initialization order, which always executes a super constructor before the subclass constructor. Virgil chooses this order so that the implicitly and explicitly initialized fields are _always_ initialized before _any_ constructor body is executed. This ensures that no partially-constructed object can escape, and that all virtual calls (even those in a constructor body) always occur on an initialized object.