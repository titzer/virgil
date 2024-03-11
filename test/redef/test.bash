#!/bin/bash

. ../common.bash redef

function do_redef_seman_tests() {
    cd seman
    print_status Semantic ""
    for f in *.v3; do
        V3C_OPTS="$(cat $f.flags)"
        run_v3c "" -test $f
    done | tee $OUT/out | $PROGRESS

    fail_fast
    cd ..
}

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	do_redef_seman_tests

	TESTS=*.v3
fi

print_status Running "v3i $V3C_OPTS"
for f in $TESTS; do
    V3C_OPTS="$(cat $f.flags)"
    run_v3c "" -test $f
done | tee $OUT/out.run | $PROGRESS
