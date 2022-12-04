#!/bin/bash

. ../common.bash aeneas

printf "  Running Aeneas unit tests..."
P=$OUT/block_order.out
pushd $VIRGIL_LOC > /dev/null
SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
run_v3c "" -fp -run $SRCS $AENEAS_LOC/../test/*.v3 -version | $PROGRESS
popd > /dev/null

