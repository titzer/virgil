#!/bin/bash

. ../common.bash wasi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

RT=$VIRGIL_LOC/rt/wasi_snapshot_preview1/wasi_snapshot_preview1.v3

target="wasm"

T=$OUT/$target
mkdir -p $T

print_compiling "$target" ""
$AENEAS_TEST -heap-size=1m -target=$target -entry-export="_start" -main-export="_start" -output=$T -multiple -rt.files=$RT $TESTS | $PROGRESS i
