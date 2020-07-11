#!/bin/bash

. ../common.bash fsi32
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
execute_tests
exit $?
