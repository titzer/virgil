# Enum Methods

Enums can have methods, declared after a `;` separator following the cases.
Methods are shared by all cases of the enum.

```
enum Planet(mass: double, radius: double) {
    MERCURY(3.303e+23, 2.4397e6),
    VENUS(4.869e+24, 6.0518e6),
    EARTH(5.976e+24, 6.37814e6);

    def surfaceGravity() -> double {
        return 6.67300E-11 * mass / (radius * radius);
    }
}
var g = Planet.EARTH.surfaceGravity();
```

## Per-case method overrides

Individual cases can override an enum-level method by declaring it inside a case body `{ ... }`.
The override must have the same name and signature as the root method.

```
enum Expr {
    ADD { def eval(a: int, b: int) -> int { return a + b; } },
    SUB { def eval(a: int, b: int) -> int { return a - b; } },
    MUL { def eval(a: int, b: int) -> int { return a * b; } };

    def eval(a: int, b: int) -> int { return 0; }  // default
}
var r = Expr.ADD.eval(3, 4);  // returns 7
```

A case that does not override a method uses the enum-level default.
Dispatch is virtual: a variable of the enum type dispatches to the correct per-case implementation at runtime.

```
def apply(op: Expr, a: int, b: int) -> int {
    return op.eval(a, b);  // virtual dispatch by tag
}
```

## Subtype enum method inheritance

Subtype enums inherit methods from their parent.
A subtype can override an inherited method for all of its cases.
Individual cases within a subtype can also provide their own overrides.

```
enum Animal { DOG, CAT, _; def speak() -> int { return 0; } }
enum Animal.Exotic {
    PARROT { def speak() -> int { return 2; } },  // per-case override
    SNAKE;

    def speak() -> int { return 1; }  // subtype-level override
}
```

Here `Animal.DOG.speak()` returns `0` (root default), `Animal.Exotic.SNAKE.speak()` returns `1` (subtype override), and `Animal.Exotic.PARROT.speak()` returns `2` (per-case override).
All dispatch goes through the root enum's dispatch table, so a variable of type `Animal` will dispatch correctly regardless of whether the value is a root case or a subtype case.
