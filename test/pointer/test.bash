#!/bin/bash

. ../common.bash pointer

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else
    TEST_LIST=*.v3
fi

LAST=0
for target in $TEST_TARGETS; do
    if [ "$target" = v3i ]; then
	continue # skip because not native target
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # skip because not native
    elif [ "$target" = wasm ]; then
	TESTS=$(ls $TEST_LIST | grep -v _64.v3)
    elif [ "$target" = x86-linux ]; then
	TESTS=$(ls $TEST_LIST | grep -v _64.v3)
    elif [ "$target" = x86-darwin ]; then
	TESTS=$(ls $TEST_LIST | grep -v _64.v3)
    elif [ "$target" = x86-64-linux ]; then
	TESTS=$(ls $TEST_LIST | grep -v _32.v3)
    elif [ "$target" = x86-64-darwin ]; then
	TESTS=$(ls $TEST_LIST | grep -v _32.v3)
    else
	continue;
    fi

    compile_target_tests $target
    execute_target_tests $target
    LAST=$?
done

exit $LAST
