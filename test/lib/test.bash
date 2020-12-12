#!/bin/bash

. ../common.bash lib

print_status Interpreting
P=$OUT/run.out
run_v3c "" *.v3 $VIRGIL_LOC/lib/util/*.v3
if [ "$?" != 0 ]; then
    printf "  %sfail%s: lib tests failed to compile\n" "$RED" "$NORM"
    exit 1
fi
run_v3c "" -run *.v3 $VIRGIL_LOC/lib/util/*.v3 | tee $P | $PROGRESS i

target=$TEST_TARGET

if [ "$target" != "" ]; then
    T=$OUT/$target
    mkdir -p $T

    C=$T/compile.out
    R=$OUT/$target/run.out

    print_compiling $target
    run_v3c $target -output=$T *.v3 $VIRGIL_LOC/lib/util/*.v3 &> $C
    check_no_red $? $C

    print_status Running $target
    if [ -x $CONFIG/execute-$target-test ]; then
	$OUT/$target/main $TESTS | tee $R | $PROGRESS i
    else
	printf "${YELLOW}skipped${NORM}\n"
    fi
fi
