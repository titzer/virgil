# Virgil Style #

A language is a set of tools and constructs for creating programs. While Virgil aims to support several paradigms of programming, including procedural, functional, and object-oriented features, there are inevitably certain patterns that are encouraged over others.

## Prefer immutability ##

Immutable objects can be freely shared and are robust against changes once they are constructed. Prefer to build smaller, immutable objects that need only to be initialized once, rather than building complex patterns of mutability and then trying to hide this fact through a wall of setters.

## Use definite initialization ##

Prefer to initialize fields directly (implicitly) with constructor parameters or through initialization expressions that are computed in terms of the fields that come before. A good class definition has an empty constructor body and is fully initialized by field initializations alone.

## Getters and setters should be minimized ##

If a field is immutable, it's usually ok to let the class's closest collaborators simply read it. Try to determine whether the cost of getters and setters is worth the benefit of flexibility and safety in each case. Use your own judgment. Setters hide effects and mutability behind a veneer of object orientation; getters offer the promise of future flexibility that may or may not be cashed in at a later time.

## Use `apply` and `map` ##

Virgil provides good support for building higher order utility functions that work over maps and arrays and lists, or any other data structure you define. Make effective use of functions. Don't try to build Java-style interfaces like `Comparable` and `Closeable` and `Function` and `Transformer`, but instead pass first class functions because it is often shorter. But use your own judgment.

## Don't try to design the world's most reusable data structures ##

Remember that programs are written to accomplish some end purpose. Making the world's most robust hash table API is of secondary concern. Build what you need and move on. Don't add unnecessary operations to your data structures to support corner cases. Sometimes it's better that strange use cases have their own dedicated data structures rather than burdening the rest of your code with more complex data structures.

## There is no right size ##

Sometimes a class is just damn complicated because its role is damn hard--like a code generator. Sometimes two classes function less well than one. Sometimes a bunch of tiny classes is the right way to go. Sometimes a single class that has its operation set as a first-class function is better. Use your own judgment.

## Be irreverent ##

Don't subscribe to the cargo cult. If you find a shorter or simpler or more robust way of doing something, do it. Don't go for religion or ceremony. Don't write reams of boilerplate code because you saw someone else do that. Don't use a lot of classes and objects out of some misplaced loyalty to a design patterns book. But do name, document, and test your code well. Be proud of it.

## Do optimize ##

Don't write stupidly slow code because it will save you five minutes of coding while the code will live on for years. Thousands of small inefficiencies can accumulate in your code and contribute to the kind of performance sludge that you may never pin down with a profiler.

## Don't over abstract ##

Use your judgment with the right level of abstraction to achieve with your code. Don't make code overly reusable or overly extensible, when most of the time it is not reused and not extended. Premature abstraction can sometimes be worse than premature optimization (in both cases the code becomes inscrutable and hard to change--but prematurely abstracted code is usually slow too).

## There isn't a standard library yet ##

There isn't such a thing as a "standard library", but there are several useful utilities in the starter zip.