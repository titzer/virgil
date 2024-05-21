#!/bin/bash

. ../common.bash targets

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

ALL_TARGETS=""

# expand targets to include the -nogc and -nort versions
for target in $(get_io_targets); do
    if [ "$target" =~ ^wasm ]; then
	ALL_TARGETS="$ALL_TARGETS $target $target-nogc"
    elif [ "$target" = "v3i" ]; then
	ALL_TARGETS="$ALL_TARGETS v3i v3i-ra"
    elif [[ "$target" =~ ^x86 ]]; then
	ALL_TARGETS="$ALL_TARGETS $target $target-nogc $target-nort"
    else
	ALL_TARGETS="$ALL_TARGETS $target"
    fi
done

for target in $ALL_TARGETS; do
    T=$OUT/$target
    mkdir -p $T

    if [[ ! "$target" =~ ^v3i ]]; then
        print_status Compiling $target
        V3C_OPTS="$V3C_OPTS -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS
    fi

    run_or_skip_io_tests $target $TESTS
done
