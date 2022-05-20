all: V3S_Tester.class

x86-linux: progress-x86-linux execute-x86-linux-test

x86-64-linux: progress-x86-64-linux execute-x86-64-linux-test

x86-darwin: progress-x86-darwin execute-x86-darwin-test

x86-64-darwin: progress-x86-64-darwin execute-x86-64-darwin-test

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

execute-x86-darwin-test: src/execute-arch-posix.c
	cc -m32 ${OPTS} -o $@ src/execute-arch-posix.c
	strip $@

execute-x86-64-darwin-test: src/execute-arch-posix.c
	cc -m64 ${OPTS} -o $@ src/execute-arch-posix.c
	strip $@

execute-x86-linux-test: src/execute-arch-posix.c
	cc -m32 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

execute-x86-64-linux-test: src/execute-arch-posix.c
	cc -m64 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

V3S_Tester.class: src/V3S_Tester.java
	javac -source 1.5 -target 1.5 -d . src/V3S_Tester.java
