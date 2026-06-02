# Extensions

Virgil lets you add methods to an existing class, component, variant, or enum,
and add fields to an existing component, from outside the original declaration.
An extension is written as a top-level `def` whose name is qualified with the
target's name:

```
def Target.newMember(args) -> R { body }     // method extension
def Target.newField: T = init;                // component field extension
```

The semantics are as if the new member had been written inside the target's
body: it has the same access to private members, takes part in virtual
dispatch, and inherits the target's type parameters.

## Method extensions

The simplest case extends a non-generic class.

```
class Token { def text: string; }
def Token.length() -> int { return this.text.length; }

var t = Token.new();
t.length();
```

Extensions can be added to any class, component, variant, or enum:

```
component Sys { def name: string = "virgil"; }
def Sys.greet() -> string { return Strings.format1("hi, %s", Sys.name); }

type Shape { case Circle(r: int); case Square(s: int); }
def Shape.area() -> int {
    match (this) {
        Circle(r) => return r * r * 3;
        Square(s) => return s * s;
    }
}

enum Color { RED, GREEN, BLUE }
def Color.brightness() -> int {
    match (this) {
        RED => return 100;
        GREEN => return 200;
        BLUE => return 50;
    }
}
```

The body sees `this` for instance methods on classes, variants, and enums,
exactly as it would inside the original declaration.

## Component field extensions

Components can grow new fields via the same syntax:

```
component Conf { def base: int = 10; }
def Conf.bump: int = Conf.base + 5;
def Conf.flag: bool;            // no initializer: uses default value
def Conf.inferred = Conf.bump * 2;   // type inferred from initializer
```

Initializers run after the original component's initializers, in declaration
order within a file. Order across files is unspecified, so an extension
initializer must not depend on fields added by another file.

Field extensions are only allowed on components (not on classes, variants, or
enums).

## Generic targets

When the target has type parameters, the extension introduces fresh names
that bind positionally to the target's parameters. The number of parameters
must match the target's.

```
class Box<T> { def value: T; }
def Box<T>.unwrap() -> T { return this.value; }     // T binds to Box's T
def Box<T>.tag<U>(other: U) -> U { return other; }   // U is the method's own
```

The names are local to the extension and need not match those used in the
original declaration. `def Box<X>.unwrap()` works just as well.

## Multi-level paths (open subtypes)

A multi-level qualifier walks into an open subtype of a variant or enum:

```
enum E { A, B, _ }
enum E.More { C, D }
def E.More.score() -> int {
    match (this) {
        C => return 100;
        D => return 200;
    }
}
```

Since open subtypes are also addressable by their unqualified name, the
shorter form works too:

```
def More.score() -> int { ... }   // same target as def E.More.score()
```

Multi-level paths apply to open subtypes (declared with a dotted form like
`enum E.More`); they do not apply to ordinary inline variant cases or enum
cases.

## Private extensions

An extension declared `private` is visible only in the file where it was
written. Because the file-scope rule applies to the extension's own file
(not the target's file), several files can independently declare a private
extension with the same name on the same target.

```
// file a.v3
class Foo { }
private def Foo.helper() -> int { return 1; }
def Foo.callA() -> int { return this.helper(); }

// file b.v3
private def Foo.helper() -> int { return 2; }
def Foo.callB() -> int { return this.helper(); }

// file main.v3
def main() -> int {
    var f = Foo.new();
    return f.callA() * 10 + f.callB();   // returns 12
}
```

Each `helper` is only visible from the file that declared it, so `callA`
resolves to file a's helper and `callB` to file b's, even though both helpers
were attached to the same `Foo`.

A non-private extension with the same name as an existing member is an error,
whether the existing member is itself non-private or comes from another
extension.
