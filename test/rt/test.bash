#!/bin/bash

. ../common.bash rt

SOURCES="RiRuntimeTest.v3"
EXE=RiRuntimeTest
RT=$VIRGIL_LOC/rt

target=x86-darwin

# TODO: test runtime on all targets
if [ "$TEST_TARGET" != "$target" ]; then
	exit 0
fi

printf "  Compiling ($target) RiRuntimeTest..."
run_v3c $target $SOURCES &> $OUT/$target.compile.out
check_no_red $? $OUT/$target.compile.out

printf "  Compiling ($target-rt) RiRuntimeTest..."
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $RT/darwin/*.v3 $RT/native/*.v3 &> $OUT/$target-rt.compile.out
check_no_red $? $OUT/$target-rt.compile.out

printf "  Compiling ($target-gc) RiRuntimeTest..."
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $RT/darwin/*.v3 $RT/native/*.v3 $RT/gc/*.v3 &> $OUT/$target-gc.compile.out
check_no_red $? $OUT/$target-gc.compile.out
