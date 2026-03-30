#!/usr/bin/env bash

. ../common.bash aeneas

if [ "$1" = "-fatal" ]; then
    FATAL="-fatal"
fi

printf "  Running Aeneas unit tests..."
P=$OUT/block_order.out
pushd $VIRGIL_LOC > /dev/null
SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
run_v3c "" -fp -run $SRCS $AENEAS_LOC/../test/*.v3 $FATAL -version | $PROGRESS
UNIT_TEST_STATUS=$?
popd > /dev/null

if (( $UNITTEST == 1 && $UNIT_TEST_STATUS != 0 )); then 
    exit 1
fi
