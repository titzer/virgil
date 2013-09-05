#!/bin/bash

. ../common.bash variants
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

if [ -z "$NATIVE" ]; then
  run_int_tests "int" ""
  run_int_tests "int-ra" "-ra"
else
 run_exec_tests
fi

exit $?
