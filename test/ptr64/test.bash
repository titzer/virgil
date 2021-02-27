#!/bin/bash

. ../common.bash ptr64

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

RUN_WASM=0 # TODO: PtrCmpSwp not supported in wasm
RUN_JVM=0
RUN_INT=0
RUN_NATIVE=0 # TODO: 64-bit pointers only available on x86-64
execute_tests
exit $?
