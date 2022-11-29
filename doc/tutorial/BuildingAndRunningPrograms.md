# Running #

Running Virgil programs is easy with the included interpreter.
If you've followed the instructions in [GettingStarted](GettingStarted.md), you should simply be able to run the command:

> % `v3i <my virgil files>`

The `v3i` (Virgil III interpreter) command will load and verify your program before running its main method.
If your program has compile errors, the errors will be reported and it will not be executed.

# Compiling #

Running programs in the interpreter is great for experimentation and testing, but is much slower than running production-quality executables.
To compile your programs to the default target platform, simply run:

> % `v3c-host <my virgil files>`

This command first senses the "host" platform and then selects the appropriate compiler backend and runtime code for it.
It then invokes the compiler which will then load and verify your program before producing an executable.
As before, any compile errors will be reported.
If compilation succeeds, an executable will be produced.
The name of the executable is derived from the name of the component in your program that contains the main method.
For example, if that component were named `MyProgram`, then an executable called `MyProgram` would be produced, and it could be executed:

> % `./MyProgram <args>`

# Target Platforms #

If you are running on a platform which the Virgil compiler natively supports, the above commands will produce native binaries.
If not, the command will typically generate a Java archive (JAR) and an associated script.
The JVM is the default target when the host is not supported, because it is the most portable.
To select a specific target platform, use the appropriate `v3c` command directly:

> % `v3c-x86-64-darwin <my virgil files>`

This will produce an executable for the `x86-64-darwin` platform.
The name of the executable is chosen in the same manner as before.
If you have no compile errors, you can execute the produced binary on an appropriate computer:

> % `./MyProgram <args>`

You could could also target `x86-linux` by simply running instead:

> % `v3c-x86-linux <my virgil files>`

> % `./MyProgram <args>`

You will find that most programs run significantly faster on a native platform than on the interpreter or the JVM.
