#!/bin/bash

. ../../common.bash x86-64-asm

S=${OUT}/test.s
L=${OUT}/test.list

NASM=$(which nasm)
if [ -z "$NASM" ]; then
	echo "  nasm assembler not installed."
	exit 0
fi

LIB_UTIL="${VIRGIL_LOC}/lib/util/*.v3"
LIB_ASM="${VIRGIL_LOC}/lib/asm/x86-64/*.v3"
LIB_TEST="${VIRGIL_LOC}/lib/test/*.v3"

printf "  Generating (v3i)..."
run_v3c "" -run ./X86_64AssemblerTestGen.v3 $LIB_ASM $LIB_UTIL $@ > $S
if [ "$?" != 0 ]; then
    printf "\n"
    cat $S
    exit $?
fi
check_passed $S


printf "  Assembling (nasm)..."
nasm -l $L $S > ${OUT}/nasm.out
check $?

printf "  Comparing..."
perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? (.*);;== (.*)/ && print "$1$2 $3\n"' $L > $L.nasm
perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? (.*);;== (.*)/ && print "$4 $3\n"' $L > $L.v3i

diff $L.nasm $L.v3i > $L.diff
X=$?
check $X

if [ $X != 0 ]; then
    echo $L.diff
    head -n 10 $L.diff
fi

printf "  Testing disassembler..."
run_v3c "" -run ./X86_64DisassemblerTest.v3 $LIB_UTIL $LIB_ASM $LIB_TEST | tee $OUT/disass.out | $PROGRESS
