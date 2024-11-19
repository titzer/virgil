#!/bin/bash

. ../common.bash bootstrap

V3C_LINK=$VIRGIL_LOC/bin/v3c

TEST_HOST=jar

for target in $TEST_TARGETS; do
    if [ "$target" = "v3i" ]; then
	continue # skip
    elif [ "$target" = "wasm" ]; then
	continue # TODO: wasm bootstrap
    elif [ "$target" = "jvm" ]; then
	target=jar
    fi

    print_line
    mkdir -p $OUT/before
    compile_aeneas "$VIRGIL_LOC/bin/stable/$TEST_HOST/Aeneas" $OUT/before $target "stable"

    mkdir -p $OUT/after
    compile_aeneas "$AENEAS_TEST" $OUT/after $target " test "

    diff -rq $OUT/before/$target $OUT/after/$target &> /dev/null
    if [ $? = 0 ]; then
	printf "  => ${GREEN}$target ok${NORM}\n"
    else
	printf "  => ${RED}$target failed${NORM}\n"
        ls -l $OUT/{before,after}/$target/
    fi
done
