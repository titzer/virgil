#!/bin/bash

. ../common.bash seman

printf "  Running semantic tests..."
run_v3c "" -test -expect=expect.txt *.v3 | $PROGRESS i
