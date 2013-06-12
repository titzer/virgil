#!/bin/bash

GREEN='[0;32m'
YELLOW='[0;33m'
RED='[0;31m'
NORM='[0;00m'

SUITE=$1
export VIRGIL_TEST_OUT=/tmp/$USER/virgil-test
OUT=$VIRGIL_TEST_OUT/$SUITE
mkdir -p $OUT

VIRGIL_LOC=${VIRGIL_LOC:=$(cd $(dirname ${BASH_SOURCE[0]}) && cd .. && pwd)}
AENEAS_SOURCES=${AENEAS_SOURCES:=$(ls $VIRGIL_LOC/aeneas/src/*/*.v3)}

UNAME=$(uname -sm)
HOST_PLATFORM=$($VIRGIL_LOC/bin/dev/sense_host | cut -d' ' -f1)
HOST_JAVA=$(which java)

if [ -z "$AENEAS_TEST" ]; then
    AENEAS_TEST=$VIRGIL_LOC/bin/v3c
fi

if [ ! -x "$AENEAS_TEST" ]; then
    echo $AENEAS_TEST: not found or not executable
    exit 1
fi

function print_status() {
	config=$(echo -n $2)
	if [ -z "$3" ]; then
		printf "  %-12s ($config)..." $1
	else
		printf "  %-12s ($config) $3..." $1
	fi
}

function print_compiling() {
	print_status Compiling "$1 $V3C_OPTS" $2
}

function check() {
	if [ "$1" = 0 ]; then
		printf "${GREEN}ok${NORM}\n"
	else
		printf "${RED}failed${NORM}\n"
		if [ "$2" != "" ]; then 
			cat $2
		fi
	fi
}

function check_red() {
	grep '31m' $1 > $1.error
	if [ $? == 0 ]; then
		printf "${RED}failed${NORM}\n"
		cat $1.error
	else
		grep passed $1 > /dev/null
		check $? $1
	fi
}

function check_no_red() {
	grep '31m' $2 > $2.error
	if [ $? == 0 ]; then
		printf "${RED}failed${NORM}\n"
		cat $2.error
	else
		check $1
	fi
}

function run_native() {
	target=$1

	print_status Running "$target/$HOST_PLATFORM"
	if [ "$HOST_PLATFORM" == "$target" ]; then
		TESTER=$VIRGIL_LOC/test/testexec-$target
		if [ ! -x $TESTER ]; then
			echo "${RED}no tester available${NORM}"
		else
			echo
			$TESTER ${VIRGIL_TEST_OUT}/$SUITE/$target $TESTS | tee ${VIRGIL_TEST_OUT}/$SUITE/$target/run.out
		fi
	else
		echo "${YELLOW}skip${NORM}"
	fi
}

function run_io_test() {
	target=$1
	local test=$2
	local args="$3"
	local expected="$4"

	if [[ "$HOST_PLATFORM" == "$target" || $target == "jar" && "$HOST_JAVA" != "" ]]; then
		print_status Running "$target" "$test"
		P=$OUT/$target/$test.out
		$OUT/$target/$test $args &> $P
		diff $expected $P > $OUT/$target/$test.diff
		check $?
	else
		print_status Skipping "$target/$HOST_PLATFORM"
		echo "${YELLOW}ok${NORM}"
	fi
}

function run_v3c() {
	local target=$1
	shift
	if [ -z "$target" ]; then
		$AENEAS_TEST $V3C_OPTS "$@"
	else
		V3C=$AENEAS_TEST $VIRGIL_LOC/bin/v3c-$target $V3C_OPTS "$@"
	fi
}

function run_int_tests() {
	print_status Interpreting "$2 $V3C_OPTS"

	P=$OUT/$1.run.out
	run_v3c "" -test -expect=expect.txt $2 $TESTS > $P
	check_red $P
}

function run_native_tests() {
	target=$1
	testtarget=$2

	mkdir -p $OUT/$target
	C=$OUT/$target/compile.out
	R=$OUT/$target/run.out
	print_compiling $1
	run_v3c "" -multiple -set-exec=false -target=$testtarget -output=$OUT/$target $TESTS &> $C
	check_red $C

	run_native $target
}

function run_exec_tests() {
	run_int_tests "int" ""
	run_int_tests "int-ra" "-ra"

	mkdir -p $OUT/jvm
	C=$OUT/jvm/compile.out
	R=$OUT/jvm/run.out
	print_compiling jvm
	run_v3c "" -set-exec=false -jvm.script=false -verbose=1 -multiple -target=jvm-test -output=$OUT/jvm -jvm.rt-path=../../rt/jvm/bin $TESTS > $C
	check_red $C

	print_status Running jvm
	if [ -z "$HOST_JAVA" ]; then
		printf "${YELLOW}skipped${NORM}\n" 
	else
		$HOST_JAVA -cp $VIRGIL_LOC/rt/jvm/bin:$OUT/jvm V3S_Tester $TESTS > $R
		check_red $R
	fi

	run_native_tests x86-darwin x86-darwin-test
	run_native_tests x86-linux x86-linux-test
}
