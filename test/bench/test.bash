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
    local R=$CONFIG/run-$target
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	if [ ! -f $t/args-test ]; then
	    trace_test_ok "no test arguments"
	elif [ ! -x $R ]; then
	    trace_test_ok "skipped $target"
	else
	    local args="$(cat $t/args-test)"
	    local P=$OUT/$target/$t.out
            $R $OUT/$target $t $args &> $P
	    diff $t/output-test $P > $OUT/$target/$t.diff
	    trace_test_retval $?
	fi
    done
}

for target in $(get_io_targets); do
    if [ "$target" = v3i ]; then
	continue # TODO: too slow
    fi

    T=$OUT/$target
    mkdir -p $T

    print_compiling $target
    compile_benchmarks $BENCHMARKS | tee $T/compile.out | $PROGRESS

    run_or_skip_io_tests $target $BENCHMARKS
done
