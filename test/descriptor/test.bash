#!/usr/bin/env bash

. ../common.bash descriptors

V3C_OPTS="$V3C_OPTS -descriptors"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_parser_tests
#TODO	do_seman_tests

	TESTS=*.v3
fi

#TODO execute_tests
