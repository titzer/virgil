#!/bin/bash

. ../common.bash linux

target=x86-linux
if [ "$TEST_TARGET" != $target ]; then
	exit 0
fi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=*.v3
fi

print_compiling $target
mkdir -p $OUT/$target
run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS &> $OUT/compile.out
check_red $OUT/compile.out

run_native $target
