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
	run_v3c "" -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -heap-size=10k $f $RT_SOURCES > $C
	trace_test_retval $?
    done
}

function do_test() {
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
    print_compiling "$target $HEAP" Aeneas

    pushd $VIRGIL_LOC > /dev/null
    SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
    run_v3c $target -output=$T $HEAP $SRCS &> $T/Aeneas-gc.compile.out
    popd > /dev/null

    check_no_red $? $T/Aeneas-gc.compile.out
    mv $T/Aeneas $T/Aeneas-gc

    print_status Testing "$target $HEAP" Aeneas
    $T/Aeneas-gc -test -rma $VIRGIL_LOC/test/execute/*.v3 | tee $T/Aeneas-gc.test.out | $PROGRESS i
}

for target in $TEST_TARGETS; do
    if [ "$target" = "int" ]; then
	continue
    elif [ "$target" = "jvm" ]; then
	continue
    elif [ "$target" = "wasm-js" ]; then
	continue # TODO: gc tests for wasm
    elif [ "$target" = "x86-darwin" ]; then
	RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/darwin/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
	do_test
    elif [ "$target" = "x86-linux" ]; then
	RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/linux/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
	do_test
    else
	continue
    fi
done
