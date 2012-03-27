#!/bin/bash

. ../../common.bash

S=${VIRGIL_TEST_OUT}/x86-asm-test.s
L=${VIRGIL_TEST_OUT}/x86-asm-test.list
T=${VIRGIL_TEST_OUT}/x86-asm-test.v3

export AENEAS_JVM_TUNING='-Xms1g -Xmx2g'

NASM=$(which nasm)
if [ -z "$NASM" ]; then
	echo "  nasm assembler not installed."
	exit 0
fi

AENEAS_SRC="$VIRGIL_LOC/aeneas/src/*/*.v3"

# TODO: use regular aeneas to run the assembler tests
AENEAS_BIG="java -server -Xmx2g -Xms2g -jar $VIRGIL_LOC/bin/stable/jar/Aeneas.jar"

if [ ! -e $T ] || [ "$(find . -newer $T)" != "" ]; then
	# the output doesn't exist, or some part of the test framework changed
	rm -f $S $L $T

	printf "  Generating $S..."
	# TODO: only use the assembler sources and util with test gen
	$AENEAS_BIG ./X86AssemblerTestGen.v3 $AENEAS_SRC > $S
	check $?

	printf "  Assembling $S..."
	nasm -l $L $S
	check $?

	printf "  Generating $T..."
	cat test_header.v3 >> $T
	perl -n -e'/; var (.*)/ && print "var $1\n"' $L >> $T
	perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? .*; (.*)/ && print "x(a.$3,\"$1$2\");\n"' $L >> $T
	cat test_footer.v3 >> $T
	check $?
fi

printf "  Running $T..."
$AENEAS_BIG $T $AENEAS_SRC
check $?
