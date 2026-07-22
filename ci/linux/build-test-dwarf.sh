#!/usr/bin/env bash
# Runs the whole test suite with "-dwarf" turned on, so that emitting debug
# information is exercised over every test program, not just test/dwarf.
#
# Note that the compiler itself is deliberately not built with -dwarf:
# AENEAS_TEST=bootstrap makes all.bash build Aeneas with $STABLE_V3C_OPTS and
# apply $V3C_OPTS only to the test programs. Building Aeneas with -dwarf would
# also defeat the bootstrap fixpoint check, which compares a compiler built
# with -dwarf against one built without it.

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

if [ "$(type -t nasm)" = "" ]; then
    echo "Install nasm"
    sudo apt -y install nasm
fi

if [ "$(type -t gdb)" = "" ]; then
    echo "Install gdb"
    sudo apt -y install gdb
fi

"${TEST_DIR}"/configure

AENEAS_TEST=bootstrap V3C_OPTS="-dwarf $@" PROGRESS_ARGS=c \
	   TEST_TARGETS="v3i x86-64-linux" "${TEST_DIR}"/all.bash
