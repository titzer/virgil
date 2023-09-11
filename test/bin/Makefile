all: V3S_Tester.class

x86-linux: progress-x86-linux test-x86-linux

x86-64-linux: progress-x86-64-linux test-x86-64-linux

x86-darwin: progress-x86-darwin test-x86-darwin

x86-64-darwin: progress-x86-64-darwin test-x86-64-darwin

OPTS=-static -O2

progress-x86-darwin: src/progress.*
	cc -m32 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-linux: src/progress.*
	cc -flto -m32 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-64-darwin: src/progress.*
	cc -m64 ${OPTS} -o $@  -Isrc src/progress.c
	strip $@

progress-arm64-darwin: src/progress.*
	cc -m64 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-64-linux: src/progress.*
	cc -flto -m64 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

test-x86-darwin: src/execute-arch-posix.c
	cc -m32 ${OPTS} -o $@ src/execute-arch-posix.c
	strip $@

test-x86-64-darwin: src/execute-arch-posix.c
	cc -m64 ${OPTS} -o $@ src/execute-arch-posix.c
	strip $@

test-x86-linux: src/execute-arch-posix.c
	cc -m32 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

test-x86-64-linux: src/execute-arch-posix.c
	cc -m64 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

V3S_Tester.class: src/V3S_Tester.java
	javac -source 1.5 -target 1.5 -d . src/V3S_Tester.java
