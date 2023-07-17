#/bin/bash

. ../common.bash debug

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

target=debug

T=$OUT/$target
mkdir -p $T

run_or_skip_io_tests $target $TESTS
