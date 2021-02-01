#!/bin/bash

. ../common.bash bootstrap

CYAN='[0;36m'
RED='[0;31m'
GREEN='[0;32m'
NORM='[0;00m'

V3C_LINK=$VIRGIL_LOC/bin/v3c

function do_aeneas_compile() {
	local HOST_AENEAS=$1
	local TARGET_DIR=$2/$3
	local target=$3
	mkdir -p $TARGET_DIR
	print_status "Compiling ($4)" "$target"
#	echo "${CYAN}Compiling ($HOST_AENEAS -> $TARGET_DIR/Aeneas)...${NORM}"

	pushd ${VIRGIL_LOC} > /dev/null
	local SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
	V3C=$HOST_AENEAS $V3C_LINK-$target $V3C_OPTS -fp $V3C_HEAP_SIZE -jvm.script -jvm.args="$AENEAS_JVM_TUNING" -output=$TARGET_DIR $SRCS
	popd > /dev/null
	if [ $? != 0 ]; then
	    echo "${RED}failed${NORM}"
	    exit $?
	else
	    echo "${GREEN}ok${NORM}"
	fi
}

TEST_TARGETS="x86-linux x86-darwin jar"
TEST_HOST=jar

for target in $TEST_TARGETS; do

    T=$OUT/$target
    mkdir -p $T/before
    do_aeneas_compile "$VIRGIL_LOC/bin/stable/$TEST_HOST/Aeneas" $T/before $target "stable"

    mkdir -p $T/after
    do_aeneas_compile "$AENEAS_TEST" $T/after $target " test "

    diff -rq $T/before $T/after 2&>1 > /dev/null
    if [ $? ]; then
	printf "    matching | ${GREEN}ok${NORM}\n"
    else
	printf "    matching | ${RED}failed${NORM}\n"
        ls -al $OUT/$target/*/*
    fi

done
