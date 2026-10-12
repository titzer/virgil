#!/usr/bin/env bash

. ../common.bash v3db

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

target=v3db

T=$OUT/$target
mkdir -p $T

run_or_skip_io_tests $target $TESTS
