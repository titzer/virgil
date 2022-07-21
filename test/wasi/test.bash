#!/bin/bash

. ../common.bash wasi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

RT=$VIRGIL_LOC/rt/wasi_snapshot_preview1/wasi_snapshot_preview1.v3

if [ -z "$TEST_TARGETS" ]; then
    TEST_TARGETS=wasi
fi

for target in $TEST_TARGETS; do
    if [ "$target" != "wasi" ]; then
	continue
    fi

    T=$OUT/$target
    mkdir -p $T

    print_compiling "$target" ""
    V3C_OPTS="$V3C_OPTS -heap-size=1m -target=wasm -entry-export=_start -main-export=_start -output=$T -rt.files=$RT" run_v3c_multiple 100 ""  $TESTS | tee $T/compile.out | $PROGRESS i

    run_or_skip_io_tests $target $TESTS
done
