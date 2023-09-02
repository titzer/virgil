# Enum Sets

A common programming problem is how to express not only a fixed group of constants, but a set of those constants, such as a set of boolean flags.
In Virgil III, every enum type `E` has an associated `E.set` type that represents a *set* of enum values.
An enum definition automatically has an associated set type; no additional work is needed.

## Basic enum set

```
enum Permission {
     READ, WRITE, EXECUTE
}
var noPerm: Permission.set;                       // default: the empty set
var filePerm: Permission.set = Permission.READ;   // a singleton set of {Permission.READ}
var allPerm = Permission.set.all;                 // represents the complete set

def setPerm(filename: string, perm: Permission.set);  // set is like any other type
def restrict(perm: Permission.set) -> Permission.set;
```

This example defines an enum representing the individual permissions that might be applied to, e.g. files.
Virgil automatically provides a set type which represents a set of permissions, which we can use anywhere any other type occurs, including as a variable's type, a parameter, return, in an array, etc.
The default value for an enum set type is the empty set, and for any enum type `E`, `E.set.all` refers to the complete set.

## Enum sets are proper values

Enum sets are not mutable collections of enum values, but are immutable and have no identity, like tuples.
Under the hood, the Virgil compiler will represent an enum set as an integer, with one bit per enum case, so an enum with 15 cases will be represented by a 15-bit integer.
No heap allocation is necessary; they are just as efficient as the typical bit fiddling code one might write in another language.
Because sets are proper values, we can use the normal Virgil equality operations (`==` and `!=`) and they work as we expect without surprises.

```
enum Foo {
    A, B, C
}
var f1: Foo.set = Foo.A;
var f2: Foo.set = Foo.set.all;
var eq: bool = (f1 == f2);         // evaluates to false
var hasAll = (f2 == Foo.set.all);  // evaluates to true
```

## Testing set membership

A basic operation of any set is querying whether a given value is in the set.
Enum set types in Virgil support the member access operator `.` followed by the enum value name as the syntax for checking if a given value is in the set.
Syntactically, an enum set value has a `bool` member that indicates whether a given value is in the set.

```
enum Flag {
    ESCAPE_QUOTES, ESCAPE_BACKSLASH, UTF8
}
def print(s: string, flags: Flag.set) {
    var useUtf8: bool = flags.UTF8;       // every member is of type bool
    if (flags.ESCAPE_QUOTES) ;            // check if we should escape quotes
    if (flags.ESCAPE_BACKSLASH) ;         // check if we should escape backslash
}
```

Virgil III enum sets can be a convenient way to group many different configuration settings into a single set.
In this example, we use a set of flags to turn on specific behaviors with a function that prints a string.
Under the hood, the Virgil compiler tests the membership of a value with a single bitmasking operation, generating efficient code that matches what one would write by hand in other languages.

## Enum set operations

For any given enum type, the empty set, the complete set, and the singleton sets for each value are simply starting points for making other sets.
In Virgil III, enum set types have the infix set operations *union* `|`, *intersection* `&`, and *subtraction* `-`, which allow us to write intuitive set-oriented code, instead of (sometimes confusing) bit operations.

```
enum Permission {
    READ, WRITE, EXECUTE
}
var readOnly: Permission.set = Permission.READ;
var readWrite = Permission.READ | Permission.WRITE;   // set union
var user1_perm = readOnly;
var user2_perm = readWrite;
var group_perm = user1_perm & user2_perm;             // set intersection

def revokeExecute(perm: Permission.set) -> Permission.set {
    return perm - Permission.EXECUTE;                 // set subtraction
}
```

Like all other operations on enum sets, the Virgil compiler will implement set operations with efficient bitwise arithmetic.
Thus all enum set operations implement proper set semantics very efficiently, with no heap allocation.

## Enum set iteration

We've now seen that we can check whether an enum set has a given value, but it is often useful to *iterate* over the values in a set.
Virgil III also supports iterating over the values in a set using a `for-in` style loop.

```
enum Day {
    SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY
}
def markVacation(workdays: Day.set) {
    var freeDays = Day.set.all - workdays;
    for (d in freeDays) markBeachDay(d);     // iterate over all {Day} values in {freeDays}
}
def markBeachDay(d: Day);
```

The `for-in` loop construct for enum sets binds a variable of the enum value type which can be used in the body of the loop.
The body will be executed for each enum value which is in the set.
Under the hood, the Virgil compiler will generate efficient bit operations on the set's representation.

## Enum values promote to enum set values

To improve the usability of enum set types, an enum value will be automatically promoted to a (singleton) set when necessary.

```
enum E {
    A, B
}
def foo(x: E.set) -> E.set;

var x: E;
var y = foo(x);     // E value is automatically promoted to E.set
```

## Implementation limits

In the current implementation of Virgil in this repository, enum set types are available for all enum declarations with 64 or fewer values.
This limitation is due to a simple approach of rewriting these operations to integer operations early in compilation and will be lifted in the future by tuples of as many integers as necessary.
