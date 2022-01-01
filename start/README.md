# Getting Started #

## Step 1 - Clone This Repository ##

This repository is not only main source control system for Virgil, including all of its
development history, it is also an up-to-date, self-contained archive that is ready to
run, without any build steps.
That means that simply cloning this repository will get you the latest bleeding-edge
version of Virgil; no package manager commands necessary!

## Step 2 - put `virgil/bin` in your `$PATH` ##

The executables in `virgil/bin` are scripts that detect your host platform and then
delegate to a platform-specific binary, automatically, without any intermediate setup
step.
Those scripts will remember your host platform and won't repeat setup a second time.
Provided your platform supports one of Virgil's targets, you won't even notice.

In fact, you may not even need this step! The scripts in `virgil/bin` are generally smart enough
to find the other parts of the Virgil repository from their own locations.
Putting this path in your environment is mostly a convenience.

## Step 3 - Run your first program ##

We can run programs directly in the Virgil interpreter, which means we can get started
right away, before we've even selected a compile target.

```
% cd virgil/apps/HelloWorld
% v3c -run HelloWorld.v3
Hello World!
```

## Step 4 - Compile your first program ##

Of course, we are usually interested in writing programs that run lean and fast on a
particular platform.
Suppose we are running on `x86-linux`, then we could compile and run our program like so:

```
% v3c-x86-linux HelloWorld.v3
% ./HelloWorld
Hello World!
```

Here, the `v3c-x86-linux` command is a script in the `virgil/bin` directory that marshals
up the runtime code for this target and passes the right compiler options. There's one
for each platform, so targeting another platform is (usually) as easy as changing the
command!

```
% v3c-jar HelloWorld.v3
% ./HelloWorld
Hello World!
```

Note that in the `jar` target, the Virgil compiler generates a little shell script that
will invoke the `java` command as a convenience for you. Pretty neat!
