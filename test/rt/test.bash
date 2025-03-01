#!/bin/bash

. ../common.bash rt

EXIT=0

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
        grep -sq 'def\ TARGET_' $test > /dev/null
        if [ $? = 0 ]; then
            target_field="TARGET_${target//-/_}"
            FLAGS="$FLAGS -redef-field=${target_field}=true"
        fi
        run_v3c $target $FLAGS -output=$T $test &> $C
        trace_test_retval $?
    done
}

# TODO: reserved code test is special in that it needs to copy and patch a binary, integrate better
function run_reserved_code_test() {
    if [ ! -x $T/reserved_code ]; then
        return 0
    fi
    if [ ! -x $CONFIG/run-$target ]; then # TODO: better output for skipped targets
        return 0
    fi
    cp $T/reserved_code $T/reserved_code2
    $T/reserved_code $T/reserved_code2
    $T/reserved_code2
}

for target in $TEST_TARGETS; do
    T=$OUT/$target
    mkdir -p $T
    
    if [ -d $target ]; then
	TESTS=$(ls *.v3 $target/*.v3)
	print_compiling $target
	compile_target_tests_with_flags $target $TESTS | $PROGRESS
	fail_fast
	run_or_skip_io_tests $target $TESTS
	fail_fast
	print_status Running $target "reserved_code"
	run_reserved_code_test | $PROGRESS
	fail_fast
    fi
done
