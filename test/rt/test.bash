#!/bin/bash

. ../common.bash rt

SOURCES="RiRuntimeTest.v3"
EXE=RiRuntimeTest
RT=$VIRGIL_LOC/rt

target=$TEST_TARGET
if [ "$target" == x86-darwin ]; then
    OS_SOURCES="$RT/darwin/*.v3"
elif [ "$target" == x86-linux ]; then
    OS_SOURCES="$RT/linux/*.v3"
else
    echo "  Pointer tests not supported on $target"
    exit 0
fi

printf "  Compiling ($target) RiRuntimeTest..."
run_v3c $target -output=$OUT $SOURCES &> $OUT/$target.compile.out
check_no_red $? $OUT/$target.compile.out

printf "  Compiling ($target-rt) RiRuntimeTest..."
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $RT/native/*.v3 &> $OUT/$target-rt.compile.out
check_no_red $? $OUT/$target-rt.compile.out

printf "  Compiling ($target-gc) RiRuntimeTest..."
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $RT/native/*.v3 $RT/gc/*.v3 &> $OUT/$target-gc.compile.out
check_no_red $? $OUT/$target-gc.compile.out

printf "  Compiling ($target) CiRuntimeApi..."
run_v3c $target -output=$OUT CiRuntimeApi.v3 &> $OUT/$target.compile.out
check_no_red $? $OUT/$target.compile.out

if [ "$HOST_PLATFORM" == "$target" ]; then
  printf "  Running   ($target) CiRuntimeApi..."
  $OUT/CiRuntimeApi &> $OUT/$target.run.out
  check $?
 
fi