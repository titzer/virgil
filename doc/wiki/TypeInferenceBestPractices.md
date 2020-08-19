# Type Inference for Variables #

The Virgil III compiler can usually infer the type of a field or local variable from its initializing expression. There are a few cases where it cannot, and there are several situations where it is not recommended to do so.

  * Empty arrays
  * Cyclic, chained field accesses
  * A `null` initializer


# Type Inference for Type Arguments #

The Virgil III compiler can usually infer type arguments to parameterized methods and classes. As for variables, there are a few cases where it is not possible. In those cases it may be necessary to manually specify the type arguments.

  * Array allocations
  * Parameterized method used as a closure
  * Parameterized class instantiation used as initializer