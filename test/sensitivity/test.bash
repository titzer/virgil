#!/bin/bash

. ../common.bash sensitivity

target=$TEST_TARGET
if [ "$target" == x86-darwin ]; then
    T=3;
elif [ "$target" == x86-linux ]; then
    T=4;
else
    # TODO: run sensitivity tests on all platforms
    echo "  Sensitivity tests not supported for target: \"$target\""
    exit 0
fi

T=$OUT/$target
mkdir -p $T
mkdir -p $T/a
mkdir -p $T/b

function run_variant() {
    local sub=$1
    local name=$2
    local dir=$T/$sub
    shift
    shift

    mkdir -p $dir
    print_compiling "$name" Aeneas
    run_v3c "$target" -heap-size=500m  -output=$dir $AENEAS_SOURCES $@ &> $dir/Aeneas.compile.out
    check_no_red $? $dir/Aeneas.compile.out
    mv $dir/Aeneas $dir/Aeneas-0

    print_compiling "$dir/Aeneas-0" Aeneas
    V3C=$dir/Aeneas-0 $VIRGIL_LOC/bin/v3c-$target $V3C_OPTS -output=$dir $AENEAS_SOURCES &> $dir/bootstrap.out
    check_no_red $? $dir/bootstrap.out
}

run_variant A "UID shift=0" ""
run_variant B "UID shift=131" "UIDBump.v3"

diff -rq $T/A/Aeneas $T/B/Aeneas &> $T/diff.out
if [ $? = 0 ]; then
    echo "  A/Aeneas == B/Aeneas ${GREEN}ok${NORM}"
    exit 0
else
    echo "  A/Aeneas == B/Aeneas ${RED}failed${NORM}"
    exit 1
fi
