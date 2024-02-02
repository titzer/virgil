#!/bin/bash

. ../common.bash float
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_parser_tests
	do_seman_tests

	TESTS=*.v3
fi

execute_tests
exit $?
