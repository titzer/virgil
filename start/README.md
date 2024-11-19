# Getting Started #

## Step 1 - Clone This Repository ##

This repository is not only the main source control system for Virgil, including all of its
development history, it is also an up-to-date, self-contained archive that is ready to
run, without any build steps.
That means that simply cloning this repository will get you the latest bleeding-edge
version of Virgil; no package manager commands necessary!

```
% git clone https://github.com/titzer/virgil
```

## Step 2 - put `virgil/bin` in your `$PATH` ##

The executables in `virgil/bin` are scripts that detect your host platform and then
delegate to a platform-specific binary, automatically, without any intermediate setup
step.
Those scripts will remember your host platform and won't repeat setup a second time.
Provided your platform supports one of Virgil's targets, you won't even notice.

In fact, you may not even need this step! The scripts in `virgil/bin` are generally smart enough
to find the other parts of the Virgil repository from their own locations.
Putting this path in your environment is mostly a convenience.

```
% cd virgil
% export PATH=$PATH:$(pwd)/bin
```

## Step 3 - Run your first program ##

We can run programs directly in the Virgil interpreter, which means we can get started
right away, before we've even selected a compile target.

```
% cd virgil/apps/HelloWorld
% v3i HelloWorld.v3
Hello World!
```

## Step 4 - Compile your first program ##

Of course, we are usually interested in writing programs that run lean and fast on a particular platform.
Suppose we are running on `x86-linux`, then we could compile and run our program like so:

```
% v3c-x86-linux HelloWorld.v3
% ./HelloWorld
Hello World!
```

Here, the `v3c-x86-linux` command is a script in the `virgil/bin` directory that passes the right compiler options to `v3c`, including the implementation of the runtime system, garbage collector, and `System` API.
There's one script for each platform, so targeting another platform is (usually) as easy as changing the command!

```
% v3c-jar HelloWorld.v3
% ./HelloWorld
Hello World!
```

Note that in the `jar` target, the Virgil compiler generates a small shell script that will invoke the `java` command as a convenience for you.
Pretty neat!

## Step 5 - Bootstrap for update-to-date features ##

The Virgil repository includes binaries of the compiler to get started on any of the supported platforms, but these binaries are updated only periodically.
These so-called "stable" binaries may lag behind the implemented features that are in the bleeding-edge compiler (whose source is controlled in this repository).
To build the latest version of the compiler for your platform, use the `aeneas bootstrap` development command, which compiles the current compiler with the stable compiler, and then compiles the current compiler with itself.

This step is necessary if you want to use unstable features that are not yet supported in the stable compiler.

```
% export PATH=$PATH:$(pwd)/bin/dev
% aeneas bootstrap
Compiling (/Users/titzer/virgil/bin/stable/jar/Aeneas -> /Users/titzer/virgil/bin/bootstrap/jar/Aeneas)...
-rwxr-xr-x  1 titzer  staff      119 Jan  1 14:18 /Users/titzer/virgil/bin/bootstrap/jar/Aeneas
-rw-r--r--  1 titzer  staff  3069237 Jan  1 14:18 /Users/titzer/virgil/bin/bootstrap/jar/Aeneas.jar
Compiling (/Users/titzer/virgil/bin/bootstrap/jar/Aeneas -> /Users/titzer/virgil/bin/current/jar/Aeneas)...
-rwxr-xr-x  1 titzer  staff      290 Jan  1 14:18 /Users/titzer/virgil/bin/current/jar/Aeneas
-rw-r--r--  1 titzer  staff  3075402 Jan  1 14:18 /Users/titzer/virgil/bin/current/jar/Aeneas.jar
```
