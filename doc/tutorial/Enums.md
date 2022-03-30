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
var workDays: Day = [Day.MONDAY, Day.TUESDAY, Day.WEDNESDAY, Day.THURSDAY, Day.FRIDAY];
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
	 return false;
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
def sayHello(day: Day) -> bool {
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
     TUESDAY("Dienstag, true),
     WEDNESDAY("Mittwoch", true),
     THURSDAY("Donnerstag", true),
     FRIDAY("Freitag", true),
     SATURDAY("Samstag", false)
}
def sayHello(day: Day) -> bool {
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
