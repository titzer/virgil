# Overview

This tutorial will teach you to the basic language concepts of Virgil III, starting from basic concepts and progressing to more complex features.
It assumes a passing familiarity with at least one programming language that favors curly-braced syntax.

If you're already fairly skilled at *another* programming language, see [Coming From](ComingFrom.md) which gives a basic flavor of Virgil in relation to other languages.

This tutorial is organized into a series of articles covered independent aspects of the language, from the basics to advanced concepts.
That way, you can jump right into a topic.

## Basic usability

* Get started with your first program, the classic [Hello World](HelloWorld.md).
* See how to develop for [WebAssembly with Virgil](wasm/DevelopingForWasm.md).

## Language concepts

* How to use [variables and definitions](Variables.md).
* Add some structure to our code instead by using [components](Components.md).
* [Primitive types](Primitives.md) are numbers, booleans, strings, characters.
* [Numbers](Numbers.md) include both fixed-size integers and floating-point numbers.
* [Methods](Methods.md) make up most of the logic of programs.
* [Local Variables](Locals.md) are how we store data in methods.
* [Arithmetic](Arith.md) on numbers in Virgil is a lot more general than other programming languages.
* [Fixed-sized Integers](FixedSizeIntegers.md) allow intuitive systems programming and save memory.
* [Arrays](Arrays.md) are key for storing large amounts of data.
* [Ranges](Ranges.md) are a generalization of arrays.
* [Strings](Strings.md) are key for dealing with files, text, etc.
* [Tuples](Tuples.md) allow using multiple values where one value is expected.
* [Tuples and Methods](TuplesAndMethods.md) go together particularly well in Virgil.
* Logic is done with familiar control constructs.
  * [Branches](Branches.md) for simple conditional logic.
  * [Loops](Loops.md) for induction and iteration over arrays and ranges.
* [Algebraic data types](ADTs.md) allow building structured data.
* [Enums](Enums.md) allow expressing fixed sets of values and even tables.
* [Enum sets](EnumSets.md) allow expressing a set of values from a given enum type.
* Virgil has switches and [pattern matching](Matches.md).
* [Ternary Expressions](Ternary.md) expressions have a slightly different syntax in Virgil.
* [Logical](Logical.md) operations can be used to combine boolean expressions.
* First-class functions and partial application support a somewhat functional programming style.
  * [Functions](Functions.md) are first-class values in Virgil.
  * [Partial Application](PartialApp.md) allows programming with higher-order functions.
  * Methods from objects or classes can be used for [functional programming](ClassesAndFunctions.md).
* Methods can have [type parameters](Typeparams.md) and be generic in their type.
* [Classes](Classes.md) are part of Virgil's support for object-oriented programming.
* Classes can [inherit](Inheritance.md) members from superclasses.
* Classes have a nice syntax for immutable fields (called [class parameters](ClassParameters.md)).
* Classes, too, can have [type parameters](ClassTypeParams.md) and thus be generic.
* Class methods can return their receiver object, [this](ReturnThis.md).
* [Casts](Casts.md) allow us to convert one type of data to another, and query the type of data or objects.
* [Layouts](Layouts.md) allow expressing exact data representations for interfacing with external software and hardware.
* [Pointers](Pointers.md) are used in platform-specific parts of the runtime.
* [Linking](Linking.md) to external code
* Type parameters don't have [variance](Variance.md) in Virgil; only subtyping on functions.
* Putting it all together, [synthesis](Synthesis.md).

## More advanced topics

* Know enough of the language? Learn how to use some [libraries](LibUtil.md).
* Virgil doesn't yet have [exceptions](Exceptions.md).
* What kind of programming [style](Style.md) should I use?
* Some [techniques](ImplNotes.md) that are used to make Virgil fast.
