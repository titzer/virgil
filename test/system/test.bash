#!/bin/bash

. ../common.bash system

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

for target in $TEST_TARGETS; do
    target=$(convert_to_io_target $target)
    
    T=$OUT/$target
    mkdir -p $T

    if [ "$target" != "int" ]; then
	print_compiling "$target" ""
	V3C_OPTS="$V3C_OPTS -heap-size=32k -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS i
    fi

    run_or_skip_io_tests $target $TESTS
done
