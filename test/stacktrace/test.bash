#!/bin/bash

. ../common.bash stacktrace

target=$TEST_TARGET
T=$OUT/$target
mkdir -p $T
P=$T/test.out
C=$T/$target-test.compile.out
rm -f $C $P
rm -f $T/*.st

if [ "$target" == x86-darwin ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/darwin/*.v3 $NATIVE_SOURCES"
elif [ "$target" == x86-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/x86-linux/*.v3 $NATIVE_SOURCES"
elif [ "$target" == x86-64-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/x86-64-linux/*.v3 $NATIVE_SOURCES"
fi

function compile_st_tests() {
    trace_test_count $#
    for f in $@; do
	trace_test_start $f
	fname="${basedir}$(basename $f)"
	fname="${fname%*.*}.v3"
	run_v3c "" -output=$T -target=$target-test -rt.sttables $fname $RT_SOURCES
	trace_test_retval $?
    done
}

function do_test() {
  basedir=$1
  tests=$2

  print_compiling "$target" "$tests"
  TESTS=$(ls $T/*.st)

  C=$T/compile.out
  ALL=$T/compile.all.out

  compile_st_tests $TESTS | $PROGRESS i

  if [ "$RUN_NATIVE" != 0 ]; then
      execute_target_tests $target
  fi
}

tests=$(ls *.v3)

print_status Gathering int "test/stacktrace/*.v3"
run_v3c "" -test -test.st -output=$T $tests | tee $P | $PROGRESS i

function compare_st_output() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	diff $t $T/$t &> $T/$t.diff
	trace_test_retval $?
    done
}

print_status Checking ""
compare_st_output *.st | $PROGRESS i

target=$TEST_TARGET
if [[ "$target" != x86-darwin && "$target" != x86-linux ]]; then
    print_status Skipping "$target/$HOST_PLATFORM"
    echo "${YELLOW}ok${NORM}"
    exit 0
fi

do_test '' 'test/stacktrace/*.v3'

rm -f $T/*.st
if [ $# -gt 0 ]; then
  TESTS="$*"
  tests='tests'
else
  TESTS=$(ls ../execute/*.v3)
  tests='test/execute/*.v3'
fi

print_status Gathering int "$tests"
run_v3c "" -test -test.st -output=$T $TESTS | tee $T/test | $PROGRESS i

do_test ../execute/ $tests
