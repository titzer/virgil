#!/bin/bash

GREEN='[0;32m'
YELLOW='[0;33m'
RED='[0;31m'
NORM='[0;00m'

export VIRGIL_TEST_OUT=/tmp/$USER/virgil-test
OUT=$VIRGIL_TEST_OUT/$1
mkdir -p $OUT

VIRGIL_LOC=${VIRGIL_LOC:=$(cd $(dirname ${BASH_SOURCE[0]}) && cd .. && pwd)}
AENEAS_SOURCES=${AENEAS_SOURCES:=$(ls $VIRGIL_LOC/aeneas/src/*/*.v3)}

UNAME=$(uname -sm)
if [ "$UNAME" == "Darwin i386" ]; then
	HOST_PLATFORM="x86-darwin"
	TEST_TARGET=${TEST_TARGET:="x86-darwin"}
elif [[ "$UNAME" == "Linux i686" || "$UNAME" == "Linux i386" || "$UNAME" == "Linux x86_64" ]]; then
	HOST_PLATFORM="x86-linux"
	TEST_TARGET=${TEST_TARGET:="jar"}
else
	HOST_PLATFORM="unknown"
	TEST_TARGET=${TEST_TARGET:="jar"}
fi

HOST_JAVA=$(which java)

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

function compile_native_runner() {
	local target=$1
	T=${VIRGIL_TEST_OUT}/$target-testexec

	if [ ! -e $T ]; then
		gcc -lpthread -o $T $VIRGIL_LOC/test/testexec.c
		if [ $? != 0 ]; then
			echo "gcc-testexec-failed"
			exit 1
		fi
	fi
	echo $T
}

function run_native() {
	test=$1
	local target=$2
	shift
	if [ "$HOST_PLATFORM" == "$target" ]; then
		TESTER=$(compile_native_runner $target)
		printf "  Running   ($target)...\n"
		$TESTER ${VIRGIL_TEST_OUT}/$test/$target $TESTS | tee ${VIRGIL_TEST_OUT}/$test/$target/run.out
	else
		echo "  Running   ($HOST_PLATFORM)...${YELLOW}skipped${NORM}"
	fi
}

function run_io_test() {
	target=$1
	local test=$2
	local args="$3"
	local expected="$4"

	if [[ "$HOST_PLATFORM" == "$target" || $target == "jar" && "$HOST_JAVA" != "" ]]; then
		printf "  Running   ($target) $test..."
		P=$OUT/$target/$test.out
		$OUT/$target/$test $args &> $P
		diff $expected $P > $OUT/$target/$test.diff
		check $?
	else
		echo "  Running   ($HOST_PLATFORM)...${YELLOW}skipped${NORM}"
	fi
}

function run_v3c() {
	local target=$1
	shift
	if [ -z "$target" ]; then
		$VIRGIL_LOC/bin/v3c "$@"
	else
		$VIRGIL_LOC/bin/v3c-$target "$@"
	fi
}