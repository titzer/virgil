# Algebraic Data Types #

Virgil III supports algebraic data types (ADTs), allowing us to build complex immutable data structures that can be manipulated and matched on.

```
type Tree {
    case Empty;
    case Leaf(value: int);
    case Node(left: Tree, right: Tree);
}
var leaf1 = Tree.Leaf(13);
var leaf2 = Tree.Leaf(14);
var node = Tree.Node(leaf1, leaf2);
var empty = Tree.Empty;
```

In Virgil, an ADT type declaration specifies a number of cases, each of which may have *parameters*.
ADT values are constructed by calling the case constructors as if they were functions.
Cases without parameters don't require any arguments and are effectively constants.

## ADTs with methods ##

Virgil allows ADTs to have method definitions as well.
We can define methods directly *in* the declaration and add specific versions of the method for certain cases.
Calling a method on a value uses the familiar `.method()` syntax.

```
type Tree {
    case Empty            { def height() -> int { return 0; } }
    case Leaf(value: int) { def height() -> int { return 1; } }
    case Node(left: Tree, right: Tree) {
    	 def height() -> int {
	     var l = left.height(), r = right.height();
	     return 1 + if(l > r, l, r);
	 }
    }

    def height() -> int; // top-level method declaration
}
var leaf1 = Tree.Leaf(99);
var leaf2 = Tree.Leaf(98);
var node = Tree.Node(leaf1, leaf2);
var x = node.height();  // == 2
```

## ADTs are immutable and use structural-equivalence ##

In Virgil, ADT values are not (necessarily) represented as objects.
Instead, ADT values are always deep-compared for equality; the case and the parameters must be equivalent.
Thus they have no identity, and the compiler may represent them more efficiently, e.g. by not allocating heap memory when not needed.

```
type Op {
     case Add;
     case Sub;
     case Inc(v: int);
}
var x = (Op.Add == Op.Sub); // false
var y = (Op.Inc(3) == Op.Sub); // false
var z = (Op.Inc(11) == Op.Inc(11)); // true, structurally equal
```

## ADT cases have types ##

In Virgil, the individual case declarations can be used as types, not just the "outer" ADT type.
This allows using them as more specific data structures throughout your program.

```
type Pet {
     case Cat(litterbox: Location);
     case Dog(toy: Toy);
}
def playWith(dog: Pet.Dog) { // accepts only dogs; sorry, no cats!
    toss(dog.toy);
}
```

## ADT tags ##

It's often useful to have a unique integer ID for each case in an ADT.
Virgil automatically provides the `tag` field (an integer) that is a constant corresponding to a case's declaration order, starting from `0`.
For example, a common use is as an index into an `Array` holding constant data, an efficient lookup that doesn't pollute the ADT definition with information specific to a particular use case.
ADTs also have the `name` field that is the `string` name of the case, which is very commonly useful.

```
type Instrument {
    case Pen;
    case Pencil;
    case Marker;
    case Quill;
}
def targetMedia = ["paper", "paper", "a whiteboard", "parchment"];
def write(w: Instrument) {
    System.puts("Write to ");
    System.puts(targetMedia[w.tag]); // looks up the appropriate medium
    System.puts(" with a ");
    System.puts(w.name);             // uses the name of the instrument
    System.puts("!\n");
}
```

## Matching ADTs ##

Virgil allows match statements to pattern-match on values of an algebraic datatype.
We use a syntax that mirrors the declaration of the ADT and allows us to bind to the parameters of each case of the ADT.
Match statements on ADTs are checked to be exhaustive: i.e. they must cover every case of the ADT, even if just by defining a default case.

```
type A {
    case B(foo: int);
    case C(bar: int);
}
def do(a: A) -> int {
    match (a) {
        B(foo) => return foo; // match and bind params of a B
        C(bar) => return bar; // match and bind params of a C
    }  // match must be exhaustive
    // unreachable, because all cases return
}
```

## Open variants ##

A variant may include a `case _` to mark it as *open*, or *extensible*.
An open variant accepts values from **subtype variants** (declared elsewhere) in addition to its own named cases.
The `case _` acts as the default for any value not matched by a named case, and may optionally define or override methods.

```
type Priority {
    case Low;
    case _;             // open: other types can extend Priority
    def level() -> int { return 0; }
}
```

## Subtype variants ##

A *subtype variant* is declared with a dotted name `A.B`, making it a specialization of an existing open variant.
The parent must have a `case _`.

```
type Priority.High {
    case Warning;
    case Critical;
    def level() -> int { return 2; }
}
```

Now `Priority.High.Warning` and `Priority.High.Critical` are valid `Priority` values.
A variable of type `Priority` can hold any case, including those from subtype variants.

```
var p: Priority = Priority.High.Warning;  // valid: High is a subtype of Priority
```

Subtype variants can themselves be open (with `case _`) and have their own subtypes, forming hierarchies of arbitrary depth.

## Methods and dispatch ##

Methods declared on a variant are inherited by its subtype variants and may be overridden.
A method declared in the `case _` body is inherited by all direct subtypes.

```
var p: Priority = Priority.Low;
p.level()   // 0: dispatches to Priority.level

p = Priority.High.Warning;
p.level()   // 2: dispatches to Priority.High.level
```

Dispatch is based on the runtime case of the value, so the right implementation is always called even when the variable has the parent type.

## Matching open variants ##

When matching a value of an open variant type, subtype variants may be named directly as match arms.
A match on an open variant **always** requires a `_` arm, since new subtypes may be added independently.

```
def describe(p: Priority) -> int {
    match (p) {
        Low  => return 0;
        High => return 1;
        _    => return -1;  // required: covers any other subtype
    }
}
```

Subtype names are written *unqualified* in match patterns — `High` rather than `Priority.High`.

You can bind and downcast the matched value using `name: SubtypePattern =>`:

```
def describe(p: Priority) -> int {
    match (p) {
        Low    => return 0;
        h: High => return h.level();  // h has type Priority.High
        _      => return -1;
    }
}
```

## Narrowing to a subtype ##

From a value of the parent type, you can test and downcast to a subtype using the query (`?`) and cast (`!`) operators:

```
var p: Priority = ...;
if (Priority.High.?(p)) {                        // true if p is a Priority.High
    var h: Priority.High = Priority.High.!(p);   // downcast; only safe after ?
    return h.level();
}
```

`T.?(v)` returns `true` if `v` is an instance of subtype `T`.
`T.!(v)` performs the downcast and is only safe to use after a successful `?` test.
