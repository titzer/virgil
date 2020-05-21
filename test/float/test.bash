#!/bin/bash

V3C_OPTS="$V3C_OPTS -fp"

jvm=0
if [ "$1" == "-jvm" ]; then
    jvm=1
    shift
fi

function do_parser_tests() {
	cd parser
	printf "  Running parser tests..."
	run_v3c "" -test -expect=expect.txt *.v3 > $OUT/out
	check_red $OUT/out
	cd ..
}

function do_seman_tests() {
	cd seman
	printf "  Running semantic tests..."
	run_v3c "" -test -expect=expect.txt *.v3 > $OUT/out
	check_red $OUT/out
	cd ..
}

. ../common.bash float
if [ $# -gt 0 ]; then
	TESTS="$@"
else
	(do_parser_tests)
	(do_seman_tests)

	TESTS=*.v3
fi

if [ "$jvm" == 1 ]; then
  run_jvm_tests
else
  run_exec_tests
fi
exit $?
