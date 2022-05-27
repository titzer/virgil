#!/bin/bash

function do_parser_tests() {
    cd parser
    print_status Parser ""
    run_v3c "" -test -expect=expect.txt *.v3 | tee $OUT/out | $PROGRESS i
    cd ..
}

function do_seman_tests() {
    cd seman
    print_status Semantic ""
    run_v3c "" -test -expect=expect.txt *.v3 | tee $OUT/out | $PROGRESS i
    cd ..
}

. ../common.bash variants

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_parser_tests)
	(do_seman_tests)

	TESTS=*.v3
fi

execute_tests
exit $?
