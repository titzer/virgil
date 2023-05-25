#!/bin/bash

. ../common.bash ptr64

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

ALL_TEST_TARGETS=$TEST_TARGETS
TEST_TARGETS=""

for target in $ALL_TEST_TARGETS; do
    if [ "$target" = v3i ]; then
	continue # skip because not native target
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # skip because not native
    elif [ "$target" = wasm-js ]; then
	continue # skip because 32-bit
    elif [ "$target" = x86-linux ]; then
	continue # skip because 32-bit
    elif [ "$target" = x86-darwin ]; then
	continue # skip because 32-bit
    else
	TEST_TARGETS="$TEST_TARGETS $target"
    fi
done

execute_tests
exit $?
