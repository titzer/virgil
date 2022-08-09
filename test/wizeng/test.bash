#!/bin/bash

. ../common.bash wizeng

if [ "$WIZENG_LOC" = "" ]; then
    printf "  WIZENG_LOC not set, ${YELLOW}skip${NORM}\n"
    exit 0
fi

export V3C=$AENEAS_TEST
$WIZENG_LOC/test/unit.sh
