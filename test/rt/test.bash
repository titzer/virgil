#!/bin/bash

. ../common.bash rt

SOURCES="RiRuntimeTest.v3"
EXE=RiRuntimeTest
N=$VIRGIL_LOC/rt/native
RT_SOURCES="$N/RiRuntime.v3 $N/NativeStackPrinter.v3 $N/NativeFileStream.v3"

function compile_run() {
    TEST=$1
    EXE=${TEST%*.*}

    print_compiling "$target" $EXE
    run_v3c $target -output=$T $TEST &> $T/$TEST.compile.out
    check_no_red $? $T/$TEST.compile.out

    print_status Running "$target" $EXE

    if [ -x $CONFIG/run-$target ]; then
        $T/$EXE &> $T/$EXE.run.out 2>$T/$EXE.run.err
        EXIT=$?

        if [ -e $TEST.err ]; then
	    diff $TEST.err $T/$EXE.run.err > $T/$TEST.run.err.diff
            EXIT=$? # ignore process exit code if there is an error file
        fi
        
        if [[ $EXIT == 0 ]] && [ -e $TEST.expect ]; then
	    diff $TEST.expect $T/$EXE.run.out > $T/$TEST.run.out.diff
            EXIT=$?
        fi

        check $EXIT
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function compile_run_target() {
    if [ -f "$1-${target}.v3" ]; then
        compile_run $1-${target}.v3
    fi
}

function do_gc_test() {
    TEST=$1
    print_compiling "$target-gc" $TEST
    V3C=$AENEAS_TEST $VIRGIL_LOC/bin/v3c-$target $V3C_OPTS -heap-size=1k -output=$T $TEST.v3 &> $T/$TEST.compile.out
    check_no_red $? $T/$TEST.compile.out

    print_status Running "$target" $TEST

    if [ -x $CONFIG/run-$target ]; then
        $T/$TEST &> $T/$TEST.run.out
        check $?
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function do_test() {
    set_os_sources $target
    T=$OUT/$target
    mkdir -p $T

    print_compiling "$target" RiRuntimeTest
    run_v3c $target -output=$T $SOURCES &> $T/compile.out
    check_no_red $? $T/compile.out

    print_compiling "$target-rt" RiRuntimeTest
    run_v3c "" -target=$target -output=$T -heap-size=1k -rt.sttables $SOURCES $OS_SOURCES $RT_SOURCES &> $T/rt.compile.out
    check_no_red $? $T/rt.compile.out

    print_compiling "$target-gc" RiRuntimeTest
    run_v3c "" -target=$target -output=$T -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $RT_SOURCES $GC_SOURCES &> $T/gc.compile.out
    check_no_red $? $T/gc.compile.out

    compile_run CiRuntimeApi.v3
    compile_run FindFunc.v3

    compile_run_target jit
    compile_run_target signal
    V3C_OPTS=-stack-size=64k compile_run_target stackoverflow
    compile_run_target usercode

    do_gc_test FinalizerTest

    do_gc_test ScannerTest
}

for target in $TEST_TARGETS; do
    if [ "$target" = x86-darwin ]; then
        do_test
    elif [ "$target" = x86-linux ]; then
        do_test
    elif [ "$target" = x86-64-linux ]; then
        do_test
    fi
done
