#!/bin/bash

function do_parser_tests() {
    cd parser
    print_status Parser ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    cd ..
}

function do_seman_tests() {
    cd seman
    print_status Semantic ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    cd ..
}

. ../common.bash adt_layout
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_parser_tests)
	(do_seman_tests)

	TESTS=*.v3
fi

execute_tests
exit $?
