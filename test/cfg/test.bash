#!/bin/bash

. ../common.bash cfg

printf "  Running CFG tests..."
P=$OUT/block_order.out
run_v3c ""  -run SsaBlockOrderTest.v3 $AENEAS_SOURCES > $P
grep "SsaBlockOrderTest passed" $P > /dev/null
check $? $P

printf "  Running MoveResolver tests..."
P=$VIRGIL_TEST_OUT/move_resolver.out
run_v3c ""  -run MoveResolverTest.v3 $AENEAS_SOURCES > $P
grep "MoveResolverTest passed" $P > /dev/null
check $? $P
