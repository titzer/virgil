#!/bin/bash

. ../common.bash linux

test=darwin
target=x86-linux
if [ "$TEST_TARGET" != $target ]; then
	exit 0
fi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=*.v3
fi

printf "  Compiling ($target)..."
mkdir -p $OUT/$target
run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS &> $OUT/compile.out
check_red $OUT/compile.out

run_native linux $target $TESTS
