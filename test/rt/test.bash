#!/bin/bash

. ../common.bash rt

function compile_target_tests_with_flags() {
    target=$1
    shift
    trace_test_count $#
    for test in $@; do
        base=$(basename $test)
        C=$T/$base.compile.out
    
        trace_test_start $test
        FLAGS=""
        if [ -f $test.flags ]; then
            FLAGS=$(cat $test.flags)
        fi
        run_v3c $target $FLAGS -output=$T $test &> $C
        trace_test_retval $?
    done
}

for target in $TEST_TARGETS; do
    T=$OUT/$target
    mkdir -p $T
    
    if [ -d $target ]; then
        TESTS=$(ls *.v3 $target/*.v3)
        print_compiling $target
        compile_target_tests_with_flags $target $TESTS | $PROGRESS
        run_or_skip_io_tests $target $TESTS
    fi
done
