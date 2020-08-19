# Variables and Definitions #

Variables store data, such as numbers, strings, and object references. Virgil III has both _mutable_ variables, which are declared with the `var` keyword, and _immutable_ variables, declared with the `def` keyword.

```

// 'var' introduces a new, mutable variable
var x: int = 0;        // with type and initializer
var y: int;            // with type, initialized to default
var z = 0;             // with initializer and inferred type```

```

// 'def' introduces a new, immutable variable
def x: int = 0;        // with type and initializer
def y: int;            // with type, initialized to default
def z = 0;             // with initializer and inferred type```

## Type Inference ##

Virgil III supports local type inference. This allows us to omit the type declaration for a variable that is declared with an initializer. If omitted, the variable's type is simply the type of its initializing expression. In some cases which we will cover later, type inference can break down, so it is not always a good idea to rely on local type inference. For now, feel free to omit variable types when it is _obvious_ what the type of the initializing expression is. There is more detail [here](TypeInferenceBestPractices.md).

```

var x = 300 + 9;
var y = 'a';
var z = "name";
var w = getMessage();
def getMessage() -> string {
return "Hello Friends!";
}```

## Scopes ##

Each variable has a _scope_, which is the range of the program in which it is active and accessible. Here we saw variables declared within a file. These variables are local to the file but live for the entire program.

Later, we will see that we can declare variables in the scope of a [method](TutorialMethods.md) (a local variable) and within the scope of a [class](TutorialClasses.md) (an instance variable). In both cases, we use the same syntax and can define both mutable and immutable variables.