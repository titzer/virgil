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

## Subtype enum method inheritance

Subtype enums inherit methods from their parent.
A subtype can override an inherited method.

```
enum Animal { DOG, CAT, _; def speak() -> int { return 0; } }
enum Animal.Exotic {
    PARROT,
    SNAKE;

    def speak() -> int { return 1; }  // override for all Exotic cases
}
```

Here `Animal.Exotic.SNAKE.speak()` returns `1` (subtype override) and `Animal.DOG.speak()` returns `0` (root default).
All dispatch goes through the root enum's dispatch table, so a variable of type `Animal` will dispatch correctly regardless of whether the value is a root case or a subtype case.
