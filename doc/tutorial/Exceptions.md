# Virgil Exceptions #

Virgil III does not have an exception handling mechanism. If your program causes a violation of the safety checks, it is immediately terminated and a stacktrace is printed which includes accurate source information. This is in preference to segmentation faults or silent memory corruption in languages like C, but more draconian than languages like Java.

## The exception types ##

Your program has the unique opportunity to generate the following errors at runtime:

  * **`!NullCheckException`** - upon access to a `null` object, array, or function
  * **`!TypeCheckException`** - upon a failed cast
  * **`!BoundsCheckException`** - upon an out-of-bounds array access
  * **`!LengthCheckException`** - when attempting to create an array with negative length
  * **`!UnimplementedException`** - when attempting to call an abstract method
  * **`!DivideByZeroException`** - upon a division or modulus with `0` divisor
  * **`!HeapOverflow`** - if there is insufficient space in the heap
  * **`!StackOverflow`** - if there is insufficient space to hold the stack

The exclamation points are to get your attention! You can avoid these errors by not doing that.

## Future Compatibility ##

Virgil may have an exception-handling mechanism in the future. The implications of adding a fully-general exception handling mechanism have not been fully considered. Experience with other language's exception handling mechanisms is that they are extremely tricky to get right, add a lot of complexity to the runtime system and compiled binaries, and can lead to terrible application APIs.

Your programs will be punished severely for their failings.