#!/usr/bin/env bash

. ../common.bash regalloc
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

execute_tests
