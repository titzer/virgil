#!/bin/bash

. ../common.bash execute
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
execute_tests
exit $?
