#!/bin/bash

. ../common.bash stacktrace
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

function compile_tests() {
    target=$1
    trace_test_count $(echo $TESTS | wc -w)
    # TODO: use -rt.files when that v3c option is in stable
    for t in $TESTS; do
	trace_test_start $t
	# XXX: use bin/dev/target-nogc?
	V3C=$AENEAS_TEST $VIRGIL_LOC/bin/v3c-$target $V3C_OPTS -output=$T $t
	EXIT_CODE=$?
	trace_test_retval $EXIT_CODE
    done
}

function run_compiled_tests() {
    target=$1
    trace_test_count $(echo $TESTS | wc -w)
    for t in $TESTS; do
	trace_test_start $t
	exe=${t%*.*}
	echo $T/$exe
	$T/$exe 2> $T/$t.err
	diff $t.expect $T/$t.err
	EXIT_CODE=$?
	trace_test_retval $EXIT_CODE
    done
}

function run_int_tests() {
    target=$1
    trace_test_count $(echo $TESTS | wc -w)
    # TODO: run multiple stacktrace tests in one Aeneas?
    for t in $TESTS; do
	trace_test_start $t
	$AENEAS_TEST -run $t > $T/$t.out
	diff $t.expect $T/$t.out
	EXIT_CODE=$?
	trace_test_retval $EXIT_CODE
    done
}

function do_tests() {
    print_compiling $target
    compile_tests $1 | tee $T/compile.out | $PROGRESS i
    print_status "Running" ""
    if [ -x $CONFIG/run-$target ]; then
	run_compiled_tests $1 | tee $T/run.out | $PROGRESS i
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function do_int_tests() {
    opt=$1
    print_status "Running" "int $opt"
    run_int_tests $1 | tee $T/run.out | $PROGRESS i
}

## Main loop over all targets
for target in $TEST_TARGETS; do
    T=$OUT/$target
    mkdir -p $T

    if [ "$target" = int ]; then
	do_int_tests
	do_int_tests -ra
	
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # TODO: stacktrace tests on jvm
    elif [ "$target" = wasm-js ]; then
	continue # TODO: stacktrace tests on wasm
    elif [ "$target" = x86-darwin ]; then
	do_tests $target
    elif [ "$target" = x86-linux ]; then
	do_tests $target
    elif [ "$target" = x86-64-linux ]; then
	do_tests $target
    fi
done

