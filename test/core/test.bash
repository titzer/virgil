#!/bin/bash

. ../common.bash core

function run_test() {
	printf "  Running $1..."
	run_v3c "" -run $1.v3 $AENEAS_SOURCES > $OUT/$1.out
	grep "$1\ passed" $OUT/$1.out > /dev/null

	check $? $OUT/$1.out
}

run_test IntTest
run_test CharTest
run_test BufferTest
