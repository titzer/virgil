#!/bin/bash

. ../common.bash stacktrace

function clear_output_dir() {
    T=$OUT/$target
    mkdir -p $T
    P=$T/test.out
    C=$T/$target-test.compile.out
    rm -f $C $P
    rm -f $T/*.st
}

function compare_st_output() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	diff $t $T/$t &> $T/$t.diff
	trace_test_retval $?
    done
}

function compile_st_tests() {
    trace_test_count $#
    for f in $@; do
	trace_test_start $f
	fname="${basedir}$(basename $f)"
	fname="${fname%*.*}.v3"
	run_v3c "" -output=$OUT/$SUBDIR/$target -target=$target-test -rt.sttables $fname $RT_SOURCES
	trace_test_retval $?
    done
}

function gather_st_tests() {
    print_status Gathering int "$tests"
    run_v3c "" -test -test.st -output=$T $TESTS | tee $T/test | $PROGRESS i
}

function run_int_tests() {
    for target in $TEST_TARGETS; do
	if [ "$target" = int ]; then
	    clear_output_dir
	    print_status Gathering int $TESTS_NAME
	    run_v3c "" -test -test.st -output=$T $TESTS_V3 | tee $P | $PROGRESS i
	    print_status Checking ""
	    compare_st_output $TESTS_ST | $PROGRESS i
	fi
    done
}

function run_compiled_tests() {
    for target in $TEST_TARGETS; do

	if  [ "$target" = x86-darwin ]; then
	    
	    clear_output_dir
	    RT_SOURCES="$VIRGIL_LOC/rt/darwin/*.v3 $NATIVE_SOURCES"
	    
	elif [ "$target" = x86-linux ]; then
	    
	    clear_output_dir
	    RT_SOURCES="$VIRGIL_LOC/rt/linux/*.v3 $NATIVE_SOURCES"
	    
	else
	    continue
	fi
	
	print_compiling "$target" "$tests"
	TESTS=$(ls $OUT/$SUBDIR/*.st)
	
	C=$T/compile.out
	ALL=$T/compile.all.out

	compile_st_tests $TESTS | $PROGRESS i
	execute_target_tests $target
	print_status Checking ""
	compare_st_output $TESTS_ST | $PROGRESS i
}

function gather_expected_st() {
    print_status Gathering int "$tests"
    run_v3c "" -test -test.st -output=$OUT/$SUBDIR $TESTS_V3 | tee $T/test | $PROGRESS i
}

if [ $# -gt 0 ]; then
    # manually-specified tests
    TESTS_NAME="manually-specified tests"
    TESTS_V3="$*"
    TESTS_ST="${TESTS_V3/.v3/.st}"
    SUBDIR=manual
    run_int_tests
    run_compiled_tests
  
else
    # run everything in stacktrace/*.v3
    TESTS_NAME='test/stacktrace/*.v3'
    TESTS_V3="*.v3"
    TESTS_ST="*.st"
    SUBDIR=stacktrace
    run_int_tests
    run_compiled_tests

    # run everything in execute/*.v3
    TESTS_NAME='test/execute/*.v3'
    TESTS_V3=$(ls ../execute/*.v3)
    TESTS_ST="" # TODO gather
    SUBDIR=execute
    gather_expected_st
    run_compiled_tests
fi

## Main loop over all targets
for target in $TEST_TARGETS; do

    if [ "$target" = int ]; then
	
	clear_output_dir
	print_status Gathering int $TESTS_A_NAME
	run_v3c "" -test -test.st -output=$T $TESTS_A | tee $P | $PROGRESS i
	print_status Checking ""
	compare_st_output *.st | $PROGRESS i
	
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # TODO: stacktrace tests on jvm
    elif [ "$target" = wasm-js ]; then
	continue # TODO: stacktrace tests on wasm
    elif [ "$target" = x86-darwin ]; then

	clear_output_dir
	RT_SOURCES="$VIRGIL_LOC/rt/darwin/*.v3 $NATIVE_SOURCES"

    elif [ "$target" = x86-linux ]; then

	clear_output_dir
	RT_SOURCES="$VIRGIL_LOC/rt/linux/*.v3 $NATIVE_SOURCES"

    fi
done

