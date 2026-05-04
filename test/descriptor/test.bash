#!/usr/bin/env bash

. ../common.bash descriptors

V3C_OPTS="$V3C_OPTS -descriptors"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_parser_tests
	do_seman_tests

	TESTS=*.v3
fi

if [ "$EXECUTE" = 1 ]; then
    execute_tests # TODO: make unconditional
fi
    
