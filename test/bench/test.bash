#!/bin/bash

. ../common.bash bench

# Test that each of the benchmarks actually compiles
cd ../../bench

if [ $# != 0 ]; then
  BENCHMARKS="$*"
else
  BENCHMARKS=$(ls */*.v3 | cut -d/ -f1 | sort | uniq)
fi

target=$TEST_TARGET
T=$OUT/$target
mkdir -p $T

function compile_benchmarks() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	run_v3c $target -output=$T Common.v3 $t/*.v3
	trace_test_retval $?
    done
}

function run_benchmarks() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	if [ -f $t/args-test ]; then
	    run_io_test $target $t "$(cat $t/args-test)" $t/output-test
	else
	    echo skipped
	fi
	trace_test_retval $?
    done
}

print_compiling $target
compile_benchmarks $BENCHMARKS | tee $T/compile.out | $PROGRESS i

print_status Running $target
run_benchmarks $BENCHMARKS | tee $T/run.out | $PROGRESS i
