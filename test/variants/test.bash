#!/bin/bash

. ../common.bash variants
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
# run_exec_tests
# TODO: complex variant tests only work on the interpreter.
run_int_tests "int" ""
exit $?
