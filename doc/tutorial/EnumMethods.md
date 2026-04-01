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

Individual cases can override an enum method by providing their own definition inside `{ }` braces.
When calling the method on a variable of the enum type, the correct override is dispatched at runtime.

```
enum Expr {
    ADD { def eval(a: int, b: int) -> int { return a + b; } },
    SUB { def eval(a: int, b: int) -> int { return a - b; } },
    MUL { def eval(a: int, b: int) -> int { return a * b; } };

    def eval(a: int, b: int) -> int { return 0; }  // default
}
def compute(op: Expr, x: int, y: int) -> int {
    return op.eval(x, y);  // virtual dispatch: calls the override for the specific case
}
```

The `_` (default) case can also have method overrides, which apply to any value that doesn't have a more specific override.

## Enum method closures

Enum methods can be used as closures, just like methods on classes or variants.
The closure captures the enum value and dispatches correctly when called.

```
enum Op {
    INC { def apply(x: int) -> int { return x + 1; } },
    DEC { def apply(x: int) -> int { return x - 1; } };

    def apply(x: int) -> int { return x; }
}
def transform(op: Op, value: int) -> int {
    var f = op.apply;   // create a closure
    return f(value);    // calls the correct override
}
```

## Subtype enum method inheritance

Subtype enums inherit methods from their parent.
A subtype can override an inherited method, and individual cases of a subtype can override it further.

```
enum Animal { DOG, CAT, _; def speak() -> int { return 0; } }
enum Animal.Exotic {
    PARROT { def speak() -> int { return 2; } },
    SNAKE;

    def speak() -> int { return 1; }  // override for all Exotic cases
}
```

Here `Animal.Exotic.PARROT.speak()` returns `2` (per-case override), `Animal.Exotic.SNAKE.speak()` returns `1` (subtype override), and `Animal.DOG.speak()` returns `0` (root default).
All dispatch goes through the root enum's dispatch table, so a variable of type `Animal` will dispatch correctly regardless of whether the value is a root case or a subtype case.
