#!/bin/bash

. ../common.bash linux

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=*.v3
fi

function do_test() {
    print_compiling $target
    mkdir -p $OUT/$target
    run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS | tee $OUT/compile.out | $PROGRESS $PROGRESS_ARGS

    execute_target_tests $target
}

for target in $TEST_TARGETS; do
    if [ "$target" = x86-linux ]; then
	do_test
    fi
done
