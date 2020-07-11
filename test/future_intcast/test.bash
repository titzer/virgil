#!/bin/bash

. ../common.bash future_intcast
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
execute_tests
exit $?
