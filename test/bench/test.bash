#!/bin/bash

. ../common.bash bench

# Test that each of the benchmarks actually compiles
cd ../../bench

if [ $# != 0 ]; then
  BENCHMARKS="$*"
else
  BENCHMARKS=$(ls */*.v3 | cut -d/ -f1 | sort | uniq)
fi

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

function do_test() {
    T=$OUT/$target
    mkdir -p $T

    print_compiling $target
    compile_benchmarks $BENCHMARKS | tee $T/compile.out | $PROGRESS i

    print_status Running $target
    if [ ! -x $CONFIG/run-$target ]; then
	echo "${YELLOW}skipped${NORM}"
    else
	run_benchmarks $BENCHMARKS | tee $T/run.out | $PROGRESS i
    fi
}

for target in $TEST_TARGETS; do
    if [ "$target" = int ]; then
	continue
    elif [ "$target" = wasm-js ]; then
	continue
    elif [ "$target" = jvm ]; then
	target=jar
    fi
    do_test
done
