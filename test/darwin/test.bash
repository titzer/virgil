#!/usr/bin/env bash

. ../common.bash darwin

chmod 444 readonly.txt

# Tests live in a subdirectory per target. The two darwin ABIs share nothing:
# the 32-bit tests use bare syscall numbers, which raise SIGSYS on x86-64, and
# 32-bit struct layouts. Test programs run with this directory as the working
# directory, so the fixtures (test.txt, readonly.txt, writable.txt) stay here.

function do_test() {
    print_compiling "$target"
    mkdir -p $OUT/$target
    run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS | tee $OUT/compile.out | $PROGRESS

    execute_target_tests $target
}

for target in $TEST_TARGETS; do
    if [ ! -d "$target" ]; then
	continue
    fi
    if [ $# == 0 ]; then
	TESTS=$(ls $target/*.v3)
    else
	TESTS=$(echo "$@" | tr ' ' '\n' | grep "^$target/")
    fi
    if [ -n "$TESTS" ]; then
	do_test
    fi
done
