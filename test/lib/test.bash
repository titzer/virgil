#!/bin/bash

. ../common.bash lib

let PROGRESS_PIPE=1
if [[ "$1" =~ "-trace-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [[ "$1" =~ "-fatal-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [ $# -gt 0 ]; then
  TESTS=$*
else
  TESTS=*.v3
fi

function do_int() {
    print_status Interpreting
    P=$OUT/run.out
    run_v3c "" $TESTS $VIRGIL_LOC/lib/util/*.v3
    if [ "$?" != 0 ]; then
	printf "  %sfail%s: lib tests failed to compile\n" "$RED" "$NORM"
	exit 1
    fi

    if [ "$PROGRESS_PIPE" = 1 ]; then
	run_v3c "" -run $TESTS $VIRGIL_LOC/lib/util/*.v3 | tee $P | $PROGRESS
    else
	run_v3c "" -run $TESTS $VIRGIL_LOC/lib/util/*.v3 | tee $P
    fi
}

function do_compiled() {
    T=$OUT/$target
    mkdir -p $T

    C=$T/compile.out
    R=$OUT/$target/run.out

    print_compiling $target
    run_v3c $target -output=$T $TESTS $VIRGIL_LOC/lib/util/*.v3 &> $C
    check_no_red $? $C

    print_status Running $target
    if [ -x $CONFIG/run-$target ]; then
	$OUT/$target/main $TESTS | tee $R | $PROGRESS
    else
	printf "${YELLOW}skipped${NORM}\n"
    fi
}

for target in $TEST_TARGETS; do
    if [ "$target" = int ]; then
	do_int
    else
	target=$(convert_to_io_target $target)
	do_compiled
    fi
done
