#!/bin/bash

. ../common.bash wasi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

for target in $TEST_TARGETS; do
    if [ "$target" != "wasm" ]; then
	continue
    fi

    target="wasm-wasi1"
    T=$OUT/$target
    mkdir -p $T

    print_compiling "$target" ""
    RT_OPT="-rt.files=$VIRGIL_LOC/rt/wasm-wasi1/wasi_snapshot_preview1.v3"
    run_v3c_multiple 100 "" $V3C_OPTS -heap-size=32k -target=wasm -entry-export=_start -main-export=_start -output=$T "$RT_OPT" $TESTS | tee $T/compile.out | $PROGRESS

    run_or_skip_io_tests $target $TESTS
done
