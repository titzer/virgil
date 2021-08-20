#!/bin/bash

V3C_OPTS="$V3C_OPTS -legacy-cast=false"
. ../common.bash future_intcast
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
execute_tests
exit $?
