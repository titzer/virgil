# Learning Virgil coming from another programming language

A lot of programmers who come to Virgil already have familiarity with another language.
That's great, Virgil is *specifically designed* so that expertise in other (particularly curly-braced) languages transfers over.
It avoids making too many controversial syntactic choices that just cause friction.

If you are coming from some of the languages below, you may find some things pleasant and familiar, while finding other things new or weird.
Never fear!
Virgil wants to challenge you without making you mad.
It's not here to insult your favorite language or start a fight.

## Coming From Java/C\#

Virgil was heavily influenced by both of these languages.
In fact, the JVM was the first execution platform where Virgil was fully self-hosting (the compiler could compile itself and run on that platform).
These main ideas from these languages are carried forward:

  * all objects are passed by reference and are either instances of classes or arrays
  * all objects are allocated on a garbage-collected heap
  * writing a class name as a type denotes a *reference* to an object, not a copy or a pointer
  * single-inheritance only of method implementations
  * first-class functions as methods from objects and classes

However, *unlike* both of these languages, Virgil does *not* have:

  * interfaces: use first-class functions, dispatch object, or generics instead
  * overloading: all methods have different names for different parameter types
  * static members: all class members are instance members; use components for static members
  * complex visibility rules: public or private only
  * lambdas (yet)
  * annotations
  * reflection
  * dynamic class loading
  * a large set of libraries (yet)

But Virgil has these features that neither of these languages have:

  * arbitrary fixed width integers in a fully-developed number tower
  * more expressive enums
  * tuples: immutable, referentially transparent multi-values
  * fully combinatoric generics: any type can be a type argument (e.g. Java has erasure; C\# lacks void)
  * algebraic data types: immutable, referentially transparent, matchable data structures
  * robust constructor chaining with truly immutable fields
  * compact array expressions
  * a whole-program, static, optimizing compiler
  * direct support for calling the kernel on supported platforms
  * for-less-than loops
  * colon-type declaration syntax
  * a slightly different ternary operator syntax
  * fully self-hosted implementation


## Coming from JavaScript

Both Virgil and JavaScript were influenced by Java, so a lot of the curly-brace syntax looks familiar.
JavaScript is a dynamically-typed language, where variables, fields, and arguments are not given explicit types.
Virgil, however, is statically typed.
In many situations, Virgil will infer the types of fields and variables (that have initialization expressions).

There are *many* features of JavaScript that Virgil lacks.

 * nested functions
 * arrow functions
 * default argument values
 * dynamic properties
 * deleting properties
 * object literals
 * prototypes
 * destructuring
 * growable arrays
 * stack- and queue-like arrays

Of these, Virgil is planning on adding lambdas in the future, using a syntax similar to JavaScript arrow functions.
Also, many years of tuple wrangling has suggested the need for destructuring assignments.

Virgil does have some things that JavaScript programmers might like:

 * familiar array expressions
 * tuples
 * algebraic data types
 * class and method delegates
 * robust constructor chaining
 * static compilation
 * truly immutable fields
 * private fields and methods


## Coming from C

## Coming from C++
