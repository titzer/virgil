#/bin/bash

. ../common.bash gc

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(cat execute.gc variants.gc large.gc)
fi

function compile_gc_tests() {
    trace_test_count $#
    for f in $@; do
	trace_test_start $f
	run_v3c "" -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -heap-size=10k $f $OS_SOURCES $NATIVE_SOURCES $GC_SOURCES
	trace_test_retval $?
    done
}

function do_test() {
    set_os_sources $target
    T=$OUT/$target
    mkdir -p $T

    C=$T/compile.out
    ALL=$T/compile.all.out
    rm -f $ALL

    # XXX: compile all the tests in one invocation of the compiler
    print_compiling "$target" ""
    compile_gc_tests $TESTS | tee $T/compile.all.out | $PROGRESS i

    execute_target_tests $target

    HEAP='-heap-size=24m'
    BEFORE=$V3C_OPTS
    V3C_OPTS="$V3C_OPTS $HEAP"
    QUIET_COMPILE=1
    compile_aeneas $AENEAS_TEST $T $target
    V3C_OPTS="$BEFORE"

    print_status Testing "$target $HEAP" Aeneas
    if [ -x $CONFIG/run-$target ]; then
	$T/$target/Aeneas -test -rma $VIRGIL_LOC/test/execute/*.v3 | tee $T/$target/Aeneas-gc.test.out | $PROGRESS i
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

for target in $TEST_TARGETS; do
    # TODO: gc tests for wasm
    if [ "$target" = "x86-darwin" ]; then
	do_test
    elif [ "$target" = "x86-linux" ]; then
	do_test
    elif [ "$target" = "x86-64-linux" ]; then
	do_test
    fi
done
