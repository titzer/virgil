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
    echo "  Runtime tests not supported on TEST_TARGET=$target"
    exit 0
fi

print_compiling "$target" RiRuntimeTest
run_v3c $target -output=$OUT $SOURCES &> $OUT/$target.compile.out
check_no_red $? $OUT/$target.compile.out

print_compiling "$target-rt" RiRuntimeTest
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $NATIVE_SOURCES &> $OUT/$target-rt.compile.out
check_no_red $? $OUT/$target-rt.compile.out

print_compiling "$target-gc" RiRuntimeTest
run_v3c "" -target=$target -output=$OUT -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $NATIVE_SOURCES $RT/gc/*.v3 &> $OUT/$target-gc.compile.out
check_no_red $? $OUT/$target-gc.compile.out

print_compiling "$target" CiRuntimeApi
run_v3c $target -output=$OUT CiRuntimeApi.v3 &> $OUT/$target.compile.out
check_no_red $? $OUT/$target.compile.out

if [ "$HOST_PLATFORM" == "$target" ]; then
  print_status Running "$target" CiRuntimeApi
  $OUT/CiRuntimeApi &> $OUT/$target.run.out
  check $?

fi
