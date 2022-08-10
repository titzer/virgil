#!/bin/bash

. ../common.bash feature

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

print_status Semantic ""
run_v3c "" -test -expect=expect.txt *.v3 | tee $OUT/out | $PROGRESS i
exit $?
