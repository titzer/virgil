#!/bin/bash

. ../common.bash aeneas

printf "  Running Aeneas unit tests..."
P=$OUT/block_order.out
run_v3c "" -fp -run $AENEAS_SOURCES $VIRGIL_LOC/lib/util/*.v3 $AENEAS_LOC/../test/*.v3 -version > $P
grep "passed" $P > /dev/null
check $? $P

