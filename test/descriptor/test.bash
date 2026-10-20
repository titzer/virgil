#!/usr/bin/env bash

. ../common.bash descriptors

V3C_OPTS="$V3C_OPTS -lang:descriptors"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_parser_tests
	do_seman_tests

	TESTS=*.v3
fi

execute_tests

# At -O2, the machine code is optimized again after descriptor accesses are lowered.
V3C_OPTS="$V3C_OPTS -O2"
execute_tests
