#!/bin/bash

. ../common.bash pointer

target="x86-darwin"
if [ "$TEST_TARGET" != $target ]; then
	exit 0
fi

TESTS=*.v3
printf "  Compiling ($target)..."
mkdir -p $OUT/$target
run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS &> $OUT/compile.out
check_red $OUT/compile.out

run_native pointer $target $TESTS
