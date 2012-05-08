#!/bin/bash

. ../../common.bash dialect-III-1

P=$OUT/dialect-III-1.out
printf "  Running III-1 dialect tests..."
run_v3c "" -test -expect=expect.txt *.v3 > $P
check_red $P
