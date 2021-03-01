#!/bin/bash

. ../common.bash darwin

chmod 444 readonly.txt

if [ $# == 0 ]; then
  TESTS=*.v3
else
  TESTS=$@
fi

function do_test() {
    print_compiling "$target"
    mkdir -p $OUT/$target
    run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS | tee $OUT/compile.out | $PROGRESS i

    execute_target_tests $target
}

for target in $TEST_TARGETS; do
    if [ "$target" = x86-darwin ]; then
	do_test
    fi
done
