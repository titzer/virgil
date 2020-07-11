#!/bin/bash

. ../common.bash pointer

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

RUN_WASM=0 # TODO: PtrCmpSwp not supported in wasm
RUN_JVM=0
execute_tests
exit $?
