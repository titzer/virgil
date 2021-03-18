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
        $T/$EXE &> $T/$EXE.run.out
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

    if [ -f "jit-${target}.v3" ]; then
        compile_run jit-${target}.v3
    fi

    print_compiling "$target-gc" FinalizerTest
    V3C=$AENEAS_TEST $VIRGIL_LOC/bin/v3c-$target $V3C_OPTS -heap-size=1k -output=$T FinalizerTest.v3 &> $T/FinalizerTest.compile.out
    check_no_red $? $T/FinalizerTest.compile.out

    print_status Running "$target" FinalizerTest

    if [ -x $CONFIG/run-$target ]; then
        $T/FinalizerTest &> $T/FinalizerTest.run.out
        check $?
    else
	echo "${YELLOW}skipped${NORM}"
    fi
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
