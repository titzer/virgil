# Local Variables #

Local variables are just [variables](TutorialVariables.md) that are defined within the body of a method. Like variable declarations that we saw for components, we simply use the same `var` and `def` keywords to define mutable and immutable variables. As before, we can rely on local type inference so that most of the time we don't need to explicit state the type of the variable.

# Default Initialization #

Like variables declared in components, any local variable that is declared with a type but no initialization expression will be automatically initialized to the _default value_ for the type. There is never any possibility of accessing an uninitialized local variable. In contrast, accessing an uninitialized local is a compile-time error in Java, and has undefined semantics in C/C++. Default initialization of local variables is useful in a surprising number of situations and is always shorter than requiring an explicit initializer.

# Scope #

The scope of a local variable is limited to the block of code in which it is declared. If it is declared in the main block of the method, it is visible from its definition point to the end of the method. If it is declared within a nested block of a [branch](TutorialBranches.md), [loop](TutorialLoops.md), or [case](TutorialMatches.md), then it is limited to the end of the respective block. A local variable is active only while the method is executed, and is _never_ accessible from outside its respective scope.