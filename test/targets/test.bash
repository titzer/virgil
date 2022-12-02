#!/bin/bash

. ../common.bash targets

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

ALL_TARGETS=""

# expand targets to include the -nogc and -nort versions
for target in $TEST_TARGETS; do
    target=$(convert_to_io_target $target)
    if [ "$target" = "wave" ]; then
	ALL_TARGETS="$ALL_TARGETS wave wave-nogc"
    elif [ "$target" = "int" ]; then
	ALL_TARGETS="$ALL_TARGETS int int-ra"
    elif [[ "$target" =~ ^x86 ]]; then
	ALL_TARGETS="$ALL_TARGETS $target $target-nogc $target-nort"
    else
	ALL_TARGETS="$ALL_TARGETS $target"
    fi
done

for target in $ALL_TARGETS; do
    T=$OUT/$target
    mkdir -p $T

    if [[ ! "$target" =~ ^int ]]; then
        print_status Compiling $target
        V3C_OPTS="$V3C_OPTS -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS $PROGRESS_ARGS
    fi

    run_or_skip_io_tests $target $TESTS
done
