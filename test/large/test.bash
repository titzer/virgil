#!/bin/bash

. ../common.bash large
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
run_exec_tests
exit $?
