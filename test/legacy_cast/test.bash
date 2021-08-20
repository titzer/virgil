#!/bin/bash

V3C_OPTS="$V3C_OPTS -legacy-cast=true"
. ../common.bash legacy_intcast

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

execute_tests
exit $?
