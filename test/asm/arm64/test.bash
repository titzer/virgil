#!/usr/bin/env bash

#Copyright 2024 Virgil Authors. All rights reserved.
#See LICENSE for details of Apache 2.0 license.

# See ./Arm64AssemblerTestGen.v3 for details on this test script.

. ../../common.bash arm64-asm

VIRGIL_OBJDUMP=${OUT}/virgil-objdump.txt
ASM=${OUT}/asm.s
OBJECT=${OUT}/asm.o
ASM_OBJDUMP=${OUT}/asm-objdump.txt
DIFF_OBJDUMP=${OUT}/diff-objdump.txt

PROBE_ASM=${OUT}/probe.s
PROBE_OBJ=${OUT}/probe.o

LIB_UTIL="${VIRGIL_LOC}/lib/util/*.v3"
LIB_ASM="${VIRGIL_LOC}/lib/asm/arm64/*.v3"

AS=$(which as)
if [ -z "$AS" ]; then
	echo "as assembler not installed."
	exit 0
fi

# Probe objdump output format by assembling a minimal instruction and
# checking whether the disassembly uses LLVM-style "; =" comments,
# GNU binutils-style "// " comments, or neither (old/unknown format).
#
# OBJDUMP_FMT values (passed to Arm64AssemblerTestGen via -redef-fields):
#   0 = old/unknown: decimal immediates, no comments
#   1 = Apple LLVM:  hex immediates (#0x2a), "; =decimal" comment on mov
#   2 = GNU newer:   hex immediates (#0x2a), "// " comment style
printf "  Detecting objdump format..."
printf "  mov w0, #42\n" > $PROBE_ASM
as -o $PROBE_OBJ $PROBE_ASM 2>/dev/null
PROBE_OUT=$(objdump -d $PROBE_OBJ 2>/dev/null)
OBJDUMP_FMT=0
if echo "$PROBE_OUT" | grep -q '; ='; then
    OBJDUMP_FMT=1   # Apple LLVM objdump
elif echo "$PROBE_OUT" | grep -q '//'; then
    OBJDUMP_FMT=2   # GNU binutils newer
fi
printf " fmt=$OBJDUMP_FMT\n"

printf "  Generating (v3i)..."
run_v3c "" -run -redef-field=OBJDUMP_FMT=$OBJDUMP_FMT ./Arm64AssemblerTestGen.v3 $LIB_ASM $LIB_UTIL $ASM $VIRGIL_OBJDUMP $OBJECT "$@"
if [ "$?" != 0 ]; then
    printf "\n"
    cat $S
    exit $?
fi
check_passed $ASM


printf "  Assembling (as)..."
as -o $OBJECT $ASM
objdump -d $OBJECT > $ASM_OBJDUMP
check $?

printf "  Comparing..."
diff -B -i -b $ASM_OBJDUMP $VIRGIL_OBJDUMP > $DIFF_OBJDUMP
X=$?
check $X

if [ $X != 0 ]; then
    echo $DIFF_OBJDUMP
    head -n 10 $DIFF_OBJDUMP
fi
