#!/bin/bash

. ../../common.bash x86-asm

S=${OUT}/test.s
L=${OUT}/test.list

NASM=$(which nasm)
if [ -z "$NASM" ]; then
	echo "  nasm assembler not installed."
	exit 0
fi

AENEAS_UTIL="${AENEAS_LOC}/util/*.v3"
AENEAS_ASM="${AENEAS_LOC}/x86/X86Assembler.v3"

printf "  Generating (aeneas)..."
run_v3c "" -run ./X86AssemblerTestGen.v3 $AENEAS_ASM $AENEAS_UTIL $@ > $S
check_passed $S

printf "  Assembling (nasm)..."
nasm -l $L $S > ${OUT}/nasm.out
check $?

printf "  Comparing..."
perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? (.*);;== (.*)/ && print "$1$2 $3\n"' $L > $L.nasm
perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? (.*);;== (.*)/ && print "$4 $3\n"' $L > $L.aeneas

diff $L.nasm $L.aeneas > $L.diff
X=$?
check $X

if [ $X != 0 ]; then
    echo $L.diff
    head -n 10 $L.diff
fi
