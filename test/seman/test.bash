#!/bin/bash

. ../common.bash seman

printf "  Running semantic tests..."
run_v3c "" -test -expect=expect.txt *.v3 > $OUT/out
check_red $OUT/out
