#!/bin/bash

. ../common.bash legacy_intcast

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=*.v3
fi

execute_tests
exit $?
