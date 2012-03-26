#!/bin/bash

. ../common.bash parser

printf "  Running parse tests..."
run_v3c "" -test -expect=expect.txt *.v3 > $OUT/out
check_red $OUT/out
