#!/bin/bash

. ../common.bash feature

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

print_status "Feature detection" ""
run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS $PROGRESS_ARGS
exit $?
