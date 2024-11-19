#!/bin/bash

. ../common.bash system

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

for target in $(get_io_targets); do
    T=$OUT/$target
    mkdir -p $T

    if [ "$target" != "v3i" ]; then
	print_compiling "$target" ""
	V3C_OPTS="$V3C_OPTS -heap-size=32k -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS
    fi

    run_or_skip_io_tests $target $TESTS
done
