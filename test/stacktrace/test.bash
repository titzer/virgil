#!/bin/bash

. ../common.bash stacktrace
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

for target in $(get_io_targets); do
    if [ "$target" = "wasm-wave" ]; then
        continue # TODO: stacktrace tests for wasm-wave
    elif [ "$target" = "wasm-linux" ]; then
        continue # TODO: stacktrace tests for wasm-linux
    elif [ "$target" = "wasm-gc-wasi1" ]; then
        continue # TODO: stacktrace tests for wasm-linux
    elif [ "$target" = "jar" ]; then
        continue # TODO: stacktrace tests for jar
    fi

    T=$OUT/$target
    mkdir -p $T

    if [[ ! "$target" =~ ^v3i ]]; then
        print_status Compiling $target
        V3C_OPTS="$V3C_OPTS -output=$T" run_v3c_multiple 100 $target $TESTS | tee $T/compile.out | $PROGRESS
    fi

    run_or_skip_io_tests $target $TESTS
done
