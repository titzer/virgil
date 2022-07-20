#!/bin/bash

. ../common.bash stacktrace
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

for target in $TEST_TARGETS; do
    if [ "$target" = "wasm-js" ]; then
	target=wave
        continue # TODO: stacktrace tests for wave
    elif [ "$target" = "jvm" ]; then
	target=jar 
        continue #TODO: stacktrace tests for jar
    fi

    T=$OUT/$target
    mkdir -p $T

    if [[ ! "$target" =~ ^int ]]; then
        print_status Compiling $target
        V3C_OPTS="$V3C_OPTS -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS i
    fi
    
    run_or_skip_io_tests $target $TESTS
done
