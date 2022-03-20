# Running #

Running Virgil programs is easy with the included interpreter. If you've followed the instructions on GettingStarted, you should simply be able to run the command:

> % `virgil <my virgil files>`

The `virgil` command will load and verify your program before running its main method. If your program has compile errors, the errors will be reported and it will not be executed.

# Compiling #

Running programs in the interpreter is great for experimentation and testing but is much slower than running production-quality executables. To compile your programs to the default target platform, simply run:

> % `virgil compile <my virgil files>`

Again, the compiler will load and verify your program before producing an executable. Any compile errors will be reported. If compilation succeeds, an executable will be produced. The name of the executable is derived from the name of the component in your program that contains the main method. For example, if that component were named `MyProgram`, then an executable called `MyProgram` would be produced, and it could be executed:

> % `./MyProgram <args>`

# Target Platforms #

The JVM is usually the default target platform because it is the most portable. However, native executables usually run much faster than the JVM and consume less memory. To compile for a different target platform, use the appropriate `v3c` command directly:

> % `v3c-x86-darwin <my virgil files>`

This will produce an executable for the x86-darwin platform. The name of the executable is chosen in the same manner as before. If you have no compile errors, you can execute the produced binary on an appropriate computer:

> % `./MyProgram <args>`

You could could also target x86-linux by simply running instead:

> % `v3c-x86-linux <my virgil files>`

> % `./MyProgram <args>`

You will find that most programs run significantly faster on a native platform than on the interpreter or the JVM.