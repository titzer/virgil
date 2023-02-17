#!/bin/bash

V3C_OPTS="$V3C_OPTS -legacy-cast=true"

function do_seman_tests() {
    cd seman
    print_status Semantic ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    cd ..
}

. ../common.bash read_only_arrays
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_seman_tests)

	TESTS=*.v3
fi

execute_tests
exit $?
