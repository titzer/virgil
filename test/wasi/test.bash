#!/bin/bash

. ../common.bash wasi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

RT=$VIRGIL_LOC/rt/wasi_snapshot_preview1/wasi_snapshot_preview1.v3

target="wasi"

T=$OUT/$target
mkdir -p $T

print_compiling "$target" ""
V3C_OPTS="$V3C_OPTS -heap-size=1m -target=wasm -entry-export=_start -main-export=_start -output=$T -rt.files=$RT" run_v3c_multiple ""  $TESTS | tee $T/compile.out | $PROGRESS i

print_status Running $target
run_or_skip_io_tests $target $TESTS
