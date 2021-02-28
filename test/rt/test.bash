#!/bin/bash

. ../common.bash rt

SOURCES="RiRuntimeTest.v3"
EXE=RiRuntimeTest
RT=$VIRGIL_LOC/rt

target=$TEST_TARGET
if [ "$target" == x86-darwin ]; then
    OS_SOURCES="$RT/darwin/*.v3"
elif [ "$target" == x86-linux ]; then
    OS_SOURCES="$RT/x86-linux/*.v3"
elif [ "$target" == x86-64-linux ]; then
    OS_SOURCES="$RT/x86-64-linux/*.v3"
else
    echo "  Runtime tests not supported on TEST_TARGET=$target"
    exit 0
fi

T=$OUT/$target
mkdir -p $T

print_compiling "$target" RiRuntimeTest
run_v3c $target -output=$T $SOURCES &> $T/compile.out
check_no_red $? $T/compile.out

print_compiling "$target-rt" RiRuntimeTest
run_v3c "" -target=$target -output=$T -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $NATIVE_SOURCES &> $T/rt.compile.out
check_no_red $? $T/rt.compile.out

print_compiling "$target-gc" RiRuntimeTest
run_v3c "" -target=$target -output=$T -heap-size=1k -rt.gc -rt.gctables -rt.sttables $SOURCES $OS_SOURCES $NATIVE_SOURCES $RT/gc/*.v3 &> $T/gc.compile.out
check_no_red $? $T/gc.compile.out

print_compiling "$target" CiRuntimeApi
run_v3c $target -output=$T CiRuntimeApi.v3 &> $T/compile.out
check_no_red $? $T/compile.out

print_compiling "$target" FindFunc
run_v3c $target -output=$T FindFunc.v3 &> $T/find.compile.out
check_no_red $? $T/find.compile.out

if [ "$TEST_TARGET=x86-linux" ]; then
    print_compiling "$target" JIT
    run_v3c $target -output=$T jit-x86-linux.v3 &> $T/jit.compile.out
    check_no_red $? $T/jit.compile.out
fi

if [ "$HOST_PLATFORM" == "$target" ]; then
  print_status Running "$target" CiRuntimeApi
  $T/CiRuntimeApi &> $T/run.out
  check $?

  print_status Running "$target" FindFunc
  $T/FindFunc &> $T/find.run.out
  check $?

  if [ -x $T/jit-$target ]; then
      print_status Running "$target" JIT
      $T/jit-$target &> $T/jit.run.out
      check $?

  fi
fi

