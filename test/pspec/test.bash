#!/usr/bin/env bash

. ../common.bash pspec

# Run each test with partial specialization, which shares code between equivalent
# instantiations of polymorphic methods.
V3C_OPTS="$V3C_OPTS -opt=+PartialSpecialization"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

execute_tests
