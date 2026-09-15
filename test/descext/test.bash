#!/usr/bin/env bash

. ../common.bash descext

V3C_OPTS="$V3C_OPTS -lang:descriptors"

# "CiRuntime" is only installed by a target, so the semantic tests need one.
SEMAN_TARGET=x86-64-linux

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else
    do_seman_tests $SEMAN_TARGET
    TEST_LIST=*.v3
fi

function compile_gc_target_tests() {
    local target=$1
    shift

    RT_FILES="$(get_rt_files $target) $(get_gc_files $target)"
    
    mkdir -p $OUT/$target
    print_compiling $target "(gc)"
    run_v3c "" $V3C_OPTS -output=$OUT/$target -target=$target-test -set-exec=false \
	    -rt.gc -rt.gctables -rt.sttables -shadow-stack-size=4k \
	    "-rt.files=$RT_FILES" -multiple $TESTS \
	| tee $OUT/$target/compile-gc.out | $PROGRESS
}

function do_tests() {
    compile_gc_target_tests $target
    fail_fast
    execute_target_tests $target
    fail_fast
}

TESTS=$(ls $TEST_LIST)
for target in $TEST_TARGETS; do
    is_gc_target $target && do_tests || do_nothing
done
