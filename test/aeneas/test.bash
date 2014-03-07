#!/bin/bash

. ../common.bash aeneas

printf "  Running Aeneas unit tests..."
P=$OUT/block_order.out
run_v3c ""  -run $AENEAS_SOURCES $AENEAS_LOC/../test/*.v3 > $P
grep "Unit tests passed." $P > /dev/null
check $? $P

