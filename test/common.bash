#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
CONFIG=$DIR/config

RUN_INT=${RUN_INT:=1}
RUN_WASM=${RUN_WASM:=1}
RUN_JVM=${RUN_JVM:=1}
RUN_NATIVE=${RUN_NATIVE:=1}

BLUE='[0;34m'
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
AENEAS_LOC=${AENEAS_LOC:=${VIRGIL_LOC}/aeneas/src}
PROGRESS=${VIRGIL_LOC}/test/config/progress

UNAME=$(uname -sm)
HOST_PLATFORM=$($VIRGIL_LOC/bin/dev/sense_host | cut -d' ' -f1)
HOST_JAVA=$(which java)
HOST_WAVE=$(which wave)

N=$VIRGIL_LOC/rt/native
NATIVE_SOURCES="$N/RiRuntime.v3 $N/NativeStackPrinter.v3 $N/NativeFileStream.v3"

AENEAS_TEST=${AENEAS_TEST:=$VIRGIL_LOC/bin/v3c}

if [ ! -x "$AENEAS_TEST" ]; then
    echo $AENEAS_TEST: not found or not executable
    exit 1
fi

if [ -z "$TEST_D8" ]; then
    TEST_D8=$VIRGIL_LOC/bin/dev/d8
fi

function line() {
    echo ================================================================================
}

function execute() {
	echo % $@
	$@
}

function print_status() {
    config=$(echo -n $2)
    if [ -z "$3" ]; then
	printf "  %-13s %-11s | "   $1 "$config"
    else
	printf "  %-13s %-11s $3 | "  $1 "$config"
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

function trace_test_count() {
    printf "##>%d\n" $1
}

function trace_test_start() {
    printf "##+%s\n" $1
}

function trace_test_retval() {
    if [ "$1" = 0 ]; then
	printf "##-ok\n"
    else
	if [ "$2" != "" ]; then
	    cat $2
	fi
	printf "##-fail\n"
    fi
}

function check_passed() {
    grep '\[0;31m' $1 > $1.error
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

function run_io_test() {
    target=$1
    local test=$2
    local args="$3"
    local expected="$4"

    if [[ "$HOST_PLATFORM" == "$target" || $target == "jar" && "$HOST_JAVA" != "" || $target == "wave" && "$HOST_WAVE" != "" || $target == "wave-nogc" && "$HOST_WAVE" != "" ]]; then
	P=$OUT/$target/$test.out
	$OUT/$target/$test $args &> $P
	diff $expected $P > $OUT/$target/$test.diff
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function run_v3c() {
    local target=$1
    shift
    if [ -z "$target" ]; then
	$AENEAS_TEST $V3C_OPTS "$@"
    else
        local F=$VIRGIL_LOC/bin/dev/v3c-$target
        if [ ! -x "$F" ]; then
            F=$VIRGIL_LOC/bin/v3c-$target
        fi
	V3C=$AENEAS_TEST $F $V3C_OPTS "$@"
    fi
}

function execute_int_tests() {
    print_status Interpreting "$2 $V3C_OPTS"

    P=$OUT/$1.run.out
    run_v3c "" -test -expect=expect.txt $2 $TESTS | $PROGRESS i
}

function compile_target_tests() {
    target=$1
    shift
    opts="$@"

    mkdir -p $OUT/$target
    C=$OUT/$target/compile.out
    print_compiling $target
    echo run_v3c "" -multiple $opts -set-exec=false -target=$target-test -output=$OUT/$target $TESTS &> $C
    run_v3c "" -multiple $opts -set-exec=false -target=$target-test -output=$OUT/$target $TESTS | $PROGRESS i
#    check_passed $C
}

function execute_target_tests() {
    target=$1
    print_status Running $target
    R=$OUT/$target/run.out
    if [ -x $CONFIG/execute-$target-test ]; then
	$CONFIG/execute-$target-test $OUT/$target $TESTS | $PROGRESS i
#	check_passed $R
    else
	printf "${YELLOW}skipped${NORM}\n"
    fi
}

function execute_tests() {
    if [ "$RUN_INT" = 1 ]; then
	execute_int_tests "int" ""
	execute_int_tests "int-ra" "-ra"
    fi

    if [ "$RUN_WASM" = 1 ]; then
        compile_target_tests wasm-js
        execute_target_tests wasm-js
    fi

    if [ "$RUN_JVM" = 1 ]; then
        compile_target_tests jvm -jvm.script=false
        execute_target_tests jvm
    fi

    if [ "$RUN_NATIVE" = 1 ]; then
	compile_target_tests x86-darwin
	execute_target_tests x86-darwin
	compile_target_tests x86-linux
	execute_target_tests x86-linux
    fi
}
