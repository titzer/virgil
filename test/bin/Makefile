all: V3S_Tester.class

execute-x86-darwin-test: src/execute-arch-posix.c
	cc -m32 -o execute-x86-darwin-test src/execute-arch-posix.c

execute-x86-64-darwin-test: src/execute-arch-posix.c
	cc -m64 -o execute-x86-darwin-test src/execute-arch-posix.c

execute-x86-linux-test: src/execute-arch-posix.c
	cc -m32 -pthread -o execute-x86-linux-test src/execute-arch-posix.c

execute-x86-64-linux-test: src/execute-arch-posix.c
	cc -m64 -pthread -o execute-x86-linux-test src/execute-arch-posix.c

V3S_Tester.class: src/V3S_Tester.java
	javac -source 1.5 -target 1.5 -d . src/V3S_Tester.java
