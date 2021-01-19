all: V3S_Tester.class

x86-linux: progress-x86-linux execute-x86-linux-test

x86-64-linux: progress-x86-64-linux execute-x86-64-linux-test

x86-darwin: progress-x86-darwin execute-x86-darwin-test

x86-64-darwin: progress-x86-64-darwin execute-x86-64-darwin-test

progress-x86-darwin: src/progress.*
	cc -m32 -o progress-x86-darwin -Isrc src/progress.c

progress-x86-linux: src/progress.*
	cc -m32 -o progress-x86-linux -Isrc src/progress.c

progress-x86-64-darwin: src/progress.*
	cc -m64 -o progress-x86-64-darwin -Isrc src/progress.c

progress-arm64-darwin: src/progress.*
	cc -m64 -o progress-arm64-darwin -Isrc src/progress.c

progress-x86-64-linux: src/progress.*
	cc -m64 -o progress-x86-64-linux -Isrc src/progress.c

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
