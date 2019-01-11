#!/bin/bash

. ../common.bash darwin

target=x86-darwin
if [ "$TEST_TARGET" != $target ]; then
	exit 0
fi

if [ "$RUN_NATIVE" == 0 ]; then
    echo "  Darwin tests disabled by RUN_NATIVE environment variable"
    exit 0
fi

chmod 444 readonly.txt

if [ $# == 0 ]; then
  TESTS=*.v3
else
  TESTS=$@
fi

print_compiling "$target"
mkdir -p $OUT/$target
run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS &> $OUT/compile.out
check_red $OUT/compile.out

run_native $target
