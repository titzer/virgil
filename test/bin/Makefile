all: V3S_Tester.class

x86-linux: progress-x86-linux test-x86-linux

x86-64-linux: progress-x86-64-linux test-x86-64-linux

x86-darwin: progress-x86-darwin test-x86-darwin

x86-64-darwin: progress-x86-64-darwin test-x86-64-darwin

arm64-linux: progress-arm64-linux test-arm64-linux

arm64-darwin: progress-arm64-darwin test-arm64-darwin

# Build the binaries for a linux target in a docker container, e.g. from a darwin host.
DOCKER_MAKE=docker run --rm -v ${CURDIR}:${CURDIR} -w ${CURDIR}
DOCKER_DEPS=apk add --no-cache gcc musl-dev make > /dev/null

docker-x86-linux:
	${DOCKER_MAKE} --platform linux/386 i386/alpine:3.20 sh -c "${DOCKER_DEPS} && make -B x86-linux"

docker-x86-64-linux:
	${DOCKER_MAKE} --platform linux/amd64 alpine:3.20 sh -c "${DOCKER_DEPS} && make -B x86-64-linux"

docker-arm64-linux:
	${DOCKER_MAKE} --platform linux/arm64 alpine:3.20 sh -c "${DOCKER_DEPS} && make -B arm64-linux"

OPTS=-static -O2

# Darwin has no static libc; target the oldest system that might run the tests.
X86_64_DARWIN_OPTS=-arch x86_64 -mmacosx-version-min=10.13 -O2
ARM64_DARWIN_OPTS=-arch arm64 -mmacosx-version-min=11.0 -O2

progress-x86-darwin: src/progress.*
	cc -m32 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-linux: src/progress.*
	cc -flto -m32 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-64-darwin: src/progress.*
	cc ${X86_64_DARWIN_OPTS} -o $@  -Isrc src/progress.c
	strip $@

progress-arm64-darwin: src/progress.*
	cc ${ARM64_DARWIN_OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-arm64-linux: src/progress.*
	cc -flto ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

progress-x86-64-linux: src/progress.*
	cc -flto -m64 ${OPTS} -o $@ -Isrc src/progress.c
	strip $@

test-x86-darwin: src/execute-arch-posix.c
	cc -m32 ${OPTS} -o $@ src/execute-arch-posix.c
	strip $@

test-x86-64-darwin: src/execute-arch-posix.c
	cc ${X86_64_DARWIN_OPTS} -o $@ src/execute-arch-posix.c
	strip $@

test-arm64-darwin: src/execute-arch-posix.c
	cc ${ARM64_DARWIN_OPTS} -o $@ src/execute-arch-posix.c
	strip $@

test-arm64-linux: src/execute-arch-posix.c
	cc ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

test-x86-linux: src/execute-arch-posix.c
	cc -m32 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

test-x86-64-linux: src/execute-arch-posix.c
	cc -m64 ${OPTS} -pthread -o $@ src/execute-arch-posix.c
	strip $@

V3S_Tester.class: src/V3S_Tester.java
	javac -source 1.5 -target 1.5 -d . src/V3S_Tester.java
