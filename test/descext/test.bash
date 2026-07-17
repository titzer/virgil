#!/usr/bin/env bash

. ../common.bash pointer

V3C_OPTS="$V3C_OPTS -descriptors"

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else
#TODO: these don't pass because CiRuntime is not available in tests    do_seman_tests

    TEST_LIST=*.v3
fi

LAST=0
for target in $TEST_TARGETS; do
    # filter out any expected failures for the target
    expected="failures.$target"
    if [ -f "$expected" ]; then
	TESTS=$(ls $TEST_LIST | grep -v -f "$expected")
    else
	TESTS=$TEST_LIST
    fi
    
    if [ "$target" = v3i ]; then
	continue # skip because not native target
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # skip because not native
    elif [ "$target" = wasm ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = wasm-gc ]; then
        continue # skip because only certain operations work
    elif [ "$target" = x86-linux ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = x86-darwin ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = x86-64-linux ]; then
	TESTS=$(ls $TESTS | grep -v _32.v3)
    elif [ "$target" = x86-64-darwin ]; then
	TESTS=$(ls $TESTS | grep -v _32.v3)
    else
	continue;
    fi

    compile_target_tests $target
    execute_target_tests $target
    LAST=$?
done

exit $LAST

# TODO
# tests that invoke GC
# semantic tests for CiRuntime.brandDescriptor
# CiRuntime.getBrandedSize(desc)
# CiRuntime.getExtension(obj) -> Range<byte>
