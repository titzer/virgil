#!/bin/bash

. ../common.bash wasmgc

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else

#   do_parser_tests
#   do_seman_tests

    TEST_LIST=*.v3
fi

LAST=0
for target in $TEST_TARGETS; do
    if [ "$target" = v3i ]; then
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _gc)
    elif [[ "$target" = jvm || "$target" = jar ]]; then
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _gc)
    elif [ "$target" = wasm ]; then
        TESTS=$(ls $TEST_LIST | grep -v _gc)
    elif [ "$target" = wasm-gc ]; then
        TESTS=$(ls $TEST_LIST)
    elif [ "$target" = x86-linux ]; then
#       TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _64 | grep -v _gc)
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _64 | grep -v _gc | grep -v ranges) # temporary, because of reg alloc issue
    elif [ "$target" = x86-darwin ]; then :
#       TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _64 | grep -v _gc)
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _64 | grep -v _gc | grep -v ranges) # temporary, because of reg alloc issue
    elif [ "$target" = x86-64-linux ]; then
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _gc)
    elif [ "$target" = x86-64-darwin ]; then
        TESTS=$(ls $TEST_LIST | grep -v _pn | grep -v _gc)
    else
	continue;
    fi

    if [ -n "$TESTS" ]; then
        compile_target_tests $target
        execute_target_tests $target
        LAST=$?
    fi
done

exit $LAST
