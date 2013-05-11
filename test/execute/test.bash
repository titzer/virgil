#!/bin/bash

. ../common.bash execute
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
run_exec_tests
exit $?
