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
$AENEAS_TEST -heap-size=1m -target=wasm -entry-export="_start" -main-export="_start" -output=$T -multiple -rt.files=$RT $V3C_OPTS $TESTS | $PROGRESS i

function run_tests() {
    trace_test_count $#
    for t in $@; do
	run_io_test2 $target $t ""
    done
}


print_status Running $target
run_tests $TESTS | $PROGRESS i
