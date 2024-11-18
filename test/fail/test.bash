#!/bin/bash

. ../common.bash core
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

execute_tests
