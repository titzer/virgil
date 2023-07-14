#/bin/bash

. ../common.bash debug

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

run_or_skip_io_tests debug $TESTS
