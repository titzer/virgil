#!/usr/bin/env bash

. ../../common.bash riscv64-asm

if [ "$TEST_ASM" = 0 ]; then
    echo "riscv64 assembler tests skipped."
    exit 0
fi

# See ./RiscV64AssemblerTestGen.v3 for details on this test. The test generator
# writes assembly text and the words our assembler produced; the GNU RISC-V
# assembler is the oracle for the text. It is found either as a cross binutils
# on the PATH or inside the docker image "virgil-riscv64-tools" (see
# ../../../ci/riscv64/Dockerfile).

ASM=${OUT}/asm.s
EXPECTED=${OUT}/expected.hex
OBJECT=${OUT}/asm.o
BINARY=${OUT}/asm.bin
ACTUAL=${OUT}/actual.hex
DIFF=${OUT}/diff.txt

LIB_UTIL="${VIRGIL_LOC}/lib/util/*.v3"
LIB_ASM="${VIRGIL_LOC}/lib/asm/riscv64/*.v3"

ARCH_FLAGS="-march=rv64g -mno-relax"
PREFIX=""
for p in riscv64-linux-gnu- riscv64-unknown-elf- riscv64-unknown-linux-gnu- riscv64-elf-; do
    if [ -n "$(which ${p}as 2>/dev/null)" ]; then
        PREFIX=$p
        break
    fi
done

if [ -n "$PREFIX" ]; then
    function assemble() {
        ${PREFIX}as $ARCH_FLAGS -o $OBJECT $ASM && ${PREFIX}objcopy -O binary -j .text $OBJECT $BINARY
    }
elif [ -n "$(which docker 2>/dev/null)" ] && docker image inspect virgil-riscv64-tools > /dev/null 2>&1; then
    function assemble() {
        docker run --rm --platform linux/amd64 -v "$OUT:/w" -w /w virgil-riscv64-tools sh -c \
            "riscv64-linux-gnu-as $ARCH_FLAGS -o asm.o asm.s && riscv64-linux-gnu-objcopy -O binary -j .text asm.o asm.bin"
    }
else
    echo "riscv64 assembler not installed (no riscv64-*-as on PATH and no virgil-riscv64-tools docker image)."
    exit 0
fi

printf "  Generating (v3i)..."
run_v3c "" -run ./RiscV64AssemblerTestGen.v3 $LIB_ASM $LIB_UTIL $ASM $EXPECTED "$@" > $OUT/gen.out 2>&1
if [ "$?" != 0 ]; then
    printf "\n"
    cat $OUT/gen.out
    exit 1
fi
check_passed $ASM
grep -q passed $ASM || exit 1

printf "  Assembling ($(wc -l < $EXPECTED | tr -d ' ') instructions)..."
assemble > $OUT/as.out 2>&1
check $? $OUT/as.out

printf "  Comparing..."
hexdump -v -e '1/4 "%08x\n"' $BINARY > $ACTUAL
diff $EXPECTED $ACTUAL > $DIFF
X=$?
check $X

if [ $X != 0 ]; then
    # Report the first few mismatches with their instruction text.
    grep -E '^[0-9]+(,[0-9]+)?c' $DIFF | head -n 10 | while read -r hunk; do
        N=${hunk%%[c,]*}
        printf "    line %s: %s\n" $N "$(sed -n ${N}p $ASM)"
        printf "      ours=%s  gnu=%s\n" "$(sed -n ${N}p $EXPECTED)" "$(sed -n ${N}p $ACTUAL)"
    done
    exit 1
fi
