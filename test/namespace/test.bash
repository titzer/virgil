#!/bin/bash

. ../common.bash namespace

function test() {
    for target in $TEST_TARGETS; do
        if [[ "$target" = "jvm" || "$target" = "jar" ]]; then
            trace_test_count 1
            trace_test_start namespace
            runner=$CONFIG/run-jar
            run_v3c "" -target=jar -output=$OUT *.v3
            $runner $OUT main
            trace_test_retval $?
        fi
    done
}

test | $PROGRESS