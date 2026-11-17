# Enums

A common programming problem is how to express a small set of constants or a fixed set of cases.
In Virgil III, fixed sets of values can be expressed as an *enum* type.
As is common in languages that support them, instead of using an integer type and symbolic constants, we make this more robust and convenient with an `enum` definition.

## Defining an enum

```
enum Day {
     SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
}
var celebrationDay: Day = Day.SATURDAY;
var backToWork: Day = Day.MONDAY;
var workDays: Array<Day> = [Day.MONDAY, Day.TUESDAY, Day.WEDNESDAY, Day.THURSDAY, Day.FRIDAY];
```

This defines the familiar set of days of the week and gives us symbolic constants for each of them.
Under the hood, the Virgil compiler will represent these values efficiently using small integers.

To refer to a enum value, we must always use the name of the enum type as a prefix.
This is slightly more verbose, but prevents confusion if multiple different enums have values with the same name.

## Matching on enums

In addition to the familiar equality (`==`) and inequality (`!=`) operators, enums can be used in `match` statements.
Virgil allows us to be more terse here, and we don't need to use the type name as the prefix for each case.

```
enum Day {
     SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
}
def isWorkday(day: Day) -> bool {
    match (day) {
    	MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY => return true;
	 	_ => return false;
    }
}
```

## The `tag` field

Like [ADTs](ADTs.md), enums have an implicit field on each value called `tag`.
This tag is a small integer assigned by the compiler to each value declared, starting from `0`.
Because the tag is an integer, we can use them, for example, as indexes into arrays or in range checks.

```
enum Day {
     SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
}
def isWorkday(day: Day) -> bool {
    return (day.tag >= Day.MONDAY.tag && day.tag <= Day.FRIDAY.tag);
}
```

## The `name` field

Like [ADTs](ADTs.md), enums also have an implicit field on each value called `name`.
This will be the value's declared variable name, without prefix.
Since we tend to declare enum values in uppercase by convention, this may not always be what you want.

```
enum Day {
     SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
}
def sayHello(day: Day) {
    System.puts("Hello, it's a beautiful ");
    System.puts(day.name);
    System.puts("!\n");
}
```

## Enum fields

In many situations, we have more information associated with an enum than just its single value.
For example, in our running `Day` example, maybe we'd like to instead print a German greeting.
We could write a method to translate a day value to a string, or we could write:

```
enum Day(germanName: string, isWorkday: bool) {
     SUNDAY("Sonntag", false),
     MONDAY("Montag", true),
     TUESDAY("Dienstag", true),
     WEDNESDAY("Mittwoch", true),
     THURSDAY("Donnerstag", true),
     FRIDAY("Freitag", true),
     SATURDAY("Samstag", false)
}
def sayHello(day: Day) {
    System.puts("Gruesse an diesem herrlichen ");
    System.puts(day.germanName);
    System.puts("!\n");
}
```

Here, we see that the `Day` enum declares *parameters* (like [class parameters](classParameters.md)), and every enum value has arguments now.
Instead of just defining values, we are basically defining a table.
These arguments will be accessible on each enum value as fields.
We don't have to write a method with a switch, or an external array somewhere and use the `.tag` field; we can just put it right in the definition!
In fact, in this example, we also subsumed the `isWorkday()` method we wrote by adding a field for `isWorkday`.

The Virgil compiler will still represent the enum value as a small integer under the hood, and field access will be a simple array access that uses the enum value as the index.
This will typically be a single machine instruction; it's hard to beat that in terms of efficiency!

## Open enums

An enum may include a `case _` to mark it as *open*, or *extensible*.
An open enum accepts values from **subtype enums** (declared elsewhere) in addition to its own named cases.

```
enum Color { RED, GREEN, BLUE, _ }
```

The `case _` must be the last case in the enum and there can be at most one per enum.

## Subtype enums

A *subtype enum* is declared with a dotted name `E.S`, making it an extension of an existing open enum.
The parent must have a `case _`.

```
enum Color { RED, GREEN, BLUE, _ }
enum Color.Pastel { PINK, LAVENDER, MINT }
```

Now `Color.Pastel.PINK`, `Color.Pastel.LAVENDER`, and `Color.Pastel.MINT` are valid `Color` values.
A variable of type `Color` can hold any case, including those from subtype enums.

```
var c: Color = Color.Pastel.PINK;  // valid: Pastel is a subtype of Color
```

Subtype enums can themselves be open (with `case _`) and have their own subtypes, forming hierarchies of arbitrary depth.

```
enum Color { RED, GREEN, BLUE, _ }
enum Color.Pastel { PINK, LAVENDER, _ }
enum Color.Pastel.Spring { CORAL, PEACH }
```

## Matching open enums

When matching a value of an open enum type, subtype enums may be named directly as match arms.
A match on an open enum **always** requires a `_` arm, since new subtypes may be added independently.

```
enum Color { RED, GREEN, BLUE, _ }
enum Color.Pastel { PINK, LAVENDER, MINT }
def describe(c: Color) -> int {
    match (c) {
        RED    => return 0;
        GREEN  => return 1;
        BLUE   => return 2;
        Pastel => return 3;  // matches any Color.Pastel case
        _      => return -1; // required: covers any other subtype
    }
}
```

Subtype names are written *unqualified* in match patterns -- `Pastel` rather than `Color.Pastel`.

## Open enums with fields

Open enums can have fields, just like regular enums.
Subtype enums inherit the parent's fields, and each case must provide values for them.

There are several ways to declare a subtype's relationship to the parent's fields:

```
enum Shape(sides: int) { TRIANGLE(3), SQUARE(4), _ }

// Form 1: restate the parent's parameters
enum Shape.Round(sides: int) { CIRCLE(0) }

// Form 2: use the 'super' keyword
enum Shape.Polygon(super) { PENTAGON(5), HEXAGON(6) }

// Form 3: implicit inheritance (no parameter list)
enum Shape.Special { STAR(10) }
```

In all forms, each case must provide argument values for all of the parent's effective fields.

## Subtypes with additional fields

Subtypes can also declare **new fields** beyond the parent's.
There are two ways to do this:

```
enum Vehicle(wheels: int) { CAR(4), BIKE(2), _ }

// Using 'super' + extra fields
enum Vehicle.Electric(super, range: int) { TESLA(4, 300), EBIKE(2, 50) }

// Restating parent fields + extra fields
enum Vehicle.Flying(wheels: int, altitude: int) { HELICOPTER(0, 5000) }
```

The parent's fields are always first in the argument list, followed by any extra fields.

New fields are accessible only on values typed as the subtype:

```
var v: Vehicle = Vehicle.Electric.TESLA;
var w = v.wheels;    // 4: inherited field, accessible on Vehicle

var e: Vehicle.Electric = Vehicle.Electric.TESLA;
var r = e.range;     // 300: new field, only accessible on Vehicle.Electric
```

## Multi-level field inheritance

Extra fields are inherited through the hierarchy.
In a multi-level hierarchy, `super` refers to the immediate parent's *effective* fields -- the root's fields plus all intermediate ancestors' extra fields.

```
enum Animal(legs: int) { DOG(4), BIRD(2), _ }
enum Animal.Pet(super, name: string) { CAT(4, "cat"), _ }
enum Animal.Pet.Exotic(super, origin: string) { PARROT(2, "parrot", "Brazil") }
```

Here `Animal.Pet.Exotic` has three effective fields: `legs` (from root), `name` (from `Animal.Pet`), and `origin` (its own).
Each case must provide values for all three, in order.

All inherited fields are accessible on subtype-typed values:

```
var p: Animal.Pet.Exotic = Animal.Pet.Exotic.PARROT;
var l = p.legs;     // 2: from root Animal
var n = p.name;     // "parrot": from intermediate Animal.Pet
var o = p.origin;   // "Brazil": own field
```

## The `name` and `shortName` fields

For subtype enum cases, the `name` field includes the subtype path.
For example, `Color.Pastel.PINK.name` returns `"Pastel.PINK"`.
The `shortName` field gives only the case name without the subtype prefix: `Color.Pastel.PINK.shortName` returns `"PINK"`.

Enums can also have [methods](EnumMethods.md), including per-case overrides with virtual dispatch.
