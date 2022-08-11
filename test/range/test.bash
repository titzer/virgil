#!/bin/bash

function do_parser_tests() {
    cd parser
    print_status Parser ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS i
    cd ..
}

function do_seman_tests() {
    cd seman
    print_status Semantic ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS i
    cd ..
}

. ../common.bash range
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_parser_tests)
	(do_seman_tests)

	TESTS=*.v3
fi

# TODO: for now, filter out all test targets that are not the interpreter
execute_int_tests "int" ""
exit $?
