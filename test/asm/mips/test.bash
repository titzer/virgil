#!/usr/bin/env bash

. ../../common.bash mips-asm

if [ "$TEST_ASM" = 0 ]; then
    echo "mips assembler tests skipped."
    exit 0
fi

LIB_UTIL="${VIRGIL_LOC}/lib/util/*.v3"
LIB_ASM="${VIRGIL_LOC}/lib/asm/mips/*.v3"
LIB_TEST="${VIRGIL_LOC}/lib/test/*.v3"

printf "  Running (v3i)..."
run_v3c "" -run ./MipsAssemblerTest.v3 $LIB_UTIL $LIB_ASM $LIB_TEST | tee $OUT/test.out | $PROGRESS
