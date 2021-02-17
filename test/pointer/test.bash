#!/bin/bash

. ../common.bash pointer

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

ALL_TEST_TARGETS=$TEST_TARGETS
TEST_TARGETS=""

for target in $ALL_TEST_TARGETS; do
    if [ "$target" = int ]; then
	continue # skip
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # skip
    elif [ "$target" = wasm-js ]; then
	continue # skip
    else
	TEST_TARGETS="$TEST_TARGETS $target"
    fi
done

execute_tests
exit $?
