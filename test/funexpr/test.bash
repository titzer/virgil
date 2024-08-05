#!/bin/bash

. ../common.bash funexpr

V3C_OPTS="$V3C_OPTS -fun-exprs"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_parser_tests
	do_seman_tests

	TESTS=*.v3
fi

execute_tests
