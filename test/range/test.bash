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
PREVIOUS_TARGETS=$TEST_TARGETS
TEST_TARGETS=""
for t in $PREVIOUS_TARGETS; do
    if [[ $t =~ "int" ]]; then
	TEST_TARGETS+=$t
    fi
done

execute_tests
exit $?
