# Tuples #

Tuples provide a quick and easy way to combine one or more values into a composite value. The syntax for doing so is remarkably straightforward. In fact you've already seen examples of using tuple values without even realizing it! Every time you call a multi-argument function, you are actually using tuple values, since tuple values are just single values enclosed in parentheses, and tuple types are just single types enclosed in parentheses.

```

// tuples with declared types
var a: (int, int) = (0, 1);
var b: (bool, int) = (true, 78);
var c: (byte, byte, byte, int) = ('a', 'b', 'c', -1111);
// tuples with type inference
var d = (0, 1);
var e = (true, 78);
var f = ('a', 'b', 'c', -1111);```

## Member access ##

Tuple elements can be accessed as if they were fields of the tuple value. Instead of field names, the elements are named as integer literals, starting with `0`.

```

// tuple members are accessed with '.' and numbered from 0
var a = (11, false);
var b = a.0;		// == 11
var c = a.1;		// == false
var d = (1, (12, 13));
var e = d.1.0;		// == 13```

Tuples also have a special member `last` that always refers to the last element in the tuple.

```

var a = (12, 42);
var b = a.last;		// == 42
var c = ((), (), (), (), 45);
var d = c.last;		// == 45 ```

## One-element tuples ##

Tuple types with just one element, or tuple values that have just one value, are equivalent to just the one type or value. This means that the tuple operator `( ... )` can be used to group types or override operator precedence.

```

// (int) is equivalent to int
var a: (int) = (0);
var b: (byte) = ('\x00');```

## Zero-element tuples ##

A zero element tuple type, `()` is exactly equivalent to the `void` type, and a zero element tuple value, `()` is exactly equal to the `void` value. This makes tuples work nicely with zero-argument and no-return functions. In fact, you've already seen this in action whenever you've used a method with no parameters or a method with no return type!

```

// type void has one value, ()
var a: void = ();
// type () is equivalent to type void
var b: () = a;
// type () or void is legal anywhere a type can appear
var c: (int, ()) = (1, ());
var d: (int, void) = (1, ());```

## Composability ##

Like arrays, tuples support any kind of element types. For any valid types `T1` ... `Tn`, `(T1, ... Tn)` is a valid type. This mean that arrays, functions, objects, `void`, and other tuples can be inside of tuples. No exceptions!

```

// complex tuples with declared types
var a: (int, (int, int)) = (0, (1, 2));
var b: ((bool, bool), (byte, byte, byte)) = ((true, true), ('a', 'b', 'c'));
// complex tuples with type inference
var c = (0, (1, 2));
var d = ((true, true), ('a', 'b', 'c'));```