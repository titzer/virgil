#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
CONFIG=$DIR/config

CYAN='[0;36m'
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
RT_LOC=$VIRGIL_LOC/rt
GC_LOC=$RT_LOC/gc
AENEAS_SOURCES=${AENEAS_SOURCES:=$(ls $VIRGIL_LOC/aeneas/src/*/*.v3)}
AENEAS_LOC=${AENEAS_LOC:=${VIRGIL_LOC}/aeneas/src}
NATIVE_SOURCES="$RT_LOC/native/*.v3"
GC_SOURCES="${GC_LOC}/*.v3"
V3C_HEAP_SIZE=${V3C_HEAP_SIZE:="-heap-size=500m"}

PROGRESS=${VIRGIL_LOC}/test/config/progress

AENEAS_TEST=${AENEAS_TEST:=$VIRGIL_LOC/bin/v3c}
TEST_TARGETS=${TEST_TARGETS:="int jvm wasm-js x86-darwin x86-linux x86-64-linux"}

if [[ ! -x "$AENEAS_TEST" && "$AENEAS_TEST" != auto ]]; then
    echo $AENEAS_TEST: not found or not executable
    exit 1
fi

function print_line() {
    echo --------------------------------------------------------------------------------
}

function echocute() {
	echo % $@
	$@
}

function print_status() {
    config=$(echo -n $2)
    if [ -z "$3" ]; then
	printf "  %-13s %-13s | "   "$1" "$config"
    else
	printf "  %-13s %-13s $3 | "  "$1" "$config"
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

function trace_test_ok() {
    if [ "$1" != "" ]; then
	printf "##-ok: %s\n" $1
    else
	printf "##-ok\n"
    fi
}

function trace_test_fail() {
    printf "##-fail: %s\n" $1
}

function trace_test_retval() {
    if [ "$1" = 0 ]; then
	printf "##-ok\n"
    else
	if [ "$2" != "" ]; then
	    cat $2
	fi
	printf "##-fail: exitcode=$1\n"
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
    R=$CONFIG/run-$target

    if [ -x $R ]; then
	P=$OUT/$target/$test.out
        $R $OUT/$target $test $args &> $P
	diff $expected $P > $OUT/$target/$test.diff
    else
	echo "target $target ${YELLOW}skipped${NORM}"
	return 1
    fi
}

function run_io_test2() {
    target=$1
    local runner=$2
    local test=$3
    local args=""

    trace_test_start $test

    if [ -f $test.args ]; then
	args=$(cat $test.args)
    fi

    local T=$OUT/$target

    if [ ! -x $runner ]; then
	trace_test_ok "skipped"
	return 0
    fi

    local P=$T/$test


    if [ -f $test.in ]; then
	V3C=$AENEAS_TEST $runner $T $test $args < $test.in > $P.out 2> $P.err
    else
	V3C=$AENEAS_TEST $runner $T $test $args > $P.out 2> $P.err
    fi
    echo $? > $P.exit

    for check in "out" "err" "exit"; do
	if [ -f $test.$check ]; then
	    diff $test.$check $P.$check | tee $P.$check.diff
	    DIFF=${PIPESTATUS[0]}
	    if [ "$DIFF" != 0 ]; then
		trace_test_fail $P.$check.diff
		return 1
	    fi
	fi
    done

    trace_test_ok
}

function run_io_tests() {
    local target=$1
    shift
    trace_test_count $#
    for t in $@; do
	run_io_test2 $target $CONFIG/run-$target $t
    done
}

function run_io_tests2() {
    local target=$1
    shift
    local runner=$1
    shift
    trace_test_count $#
    for t in $@; do
	run_io_test2 $target $runner $t
    done
}

function run_or_skip_io_tests() {
    local target=$1
    shift

    PREFIX=$CONFIG/run-$target-
    local runners=$(ls ${PREFIX}*)

    if [ -z "$runners" ]; then
	runners=$CONFIG/run-$target
	if [[ ! -x $runners ]]; then
	    echo "${YELLOW}skipped${NORM}"
	    return 0
	fi
    fi

    for runner in $runners; do
	sub=${runner/${PREFIX}/}
	print_status Running $sub
	run_io_tests2 $target $runner $@ | tee $OUT/$target/run-$sub.out | $PROGRESS i
    done

#    if [[ ! -x $CONFIG/run-$target ]]; then
#	echo "${YELLOW}skipped${NORM}"
#    else
#	run_io_tests $@ | tee $OUT/$target/run.out | $PROGRESS i
#    fi
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

function run_v3c_multiple() { # TODO: sharding
    local target=$1
    shift
    if [ -z "$target" ]; then
	$AENEAS_TEST $V3C_OPTS -multiple "$@"
    else
        local F=$VIRGIL_LOC/bin/dev/v3c-$target
        if [ ! -x "$F" ]; then
            F=$VIRGIL_LOC/bin/v3c-$target
        fi
	V3C=$AENEAS_TEST $F $V3C_OPTS -multiple "$@"
    fi
}

function execute_int_tests() {
    print_status Interpreting "$2 $V3C_OPTS"

    P=$OUT/$1.run.out
    run_v3c "" -test -expect=expect.txt $2 $TESTS | tee $OUT/run.out | $PROGRESS i
}

function compile_target_tests() {
    target=$1
    shift
    opts="$@"

    mkdir -p $OUT/$target
    C=$OUT/$target/compile.out
    print_compiling $target
    V3C_OPTS="$V3C_OPTS $opts -set-exec=false -target=$target-test -output=$OUT/$target" run_v3c_multiple ""  $TESTS | tee $C | $PROGRESS i
}

function check_cached_target_tests() {
    # XXX: improve the performance of cache comparisons
    T=$OUT/$target/
    C=$TEST_CACHE/$SUITE/$target
    L=$OUT/$target/leftover
    count=$(echo $(echo $TESTS | wc -w))
    ext=$1
    echo > $L
    echo "##>$count"
    for t in $TESTS; do
	tf=${t/.v3/}
	cached="$C/${tf}${ext}"
	gen="$T/${tf}${ext}"
	if [ -e $cached ]; then
	    diff -q $cached $gen
	    if [ "$?" = 0 ]; then
		printf "##+$t\n##-ok\n"
		continue
	    fi
	fi
	echo $cached "!=" $gen
	echo $t >> $L
    done
}

function execute_target_tests() {
    target=$1
    R=$OUT/$target/run.out
    if [ -d "$TEST_CACHE/$SUITE/$target" ]; then
	print_status "   cached" ""
	ext=""
	if [ "$target" = "wasm-js" ]; then
	   ext=".wasm"
	fi
	check_cached_target_tests $ext | tee $OUT/$target/cached.out | $PROGRESS i
	TORUN=$(cat $OUT/$target/leftover)
    else
	TORUN="$TESTS"
    fi

    if [ "$TORUN" != "" ]; then
	print_status "  running" ""

	if [ -x $CONFIG/test-$target ]; then
	    $CONFIG/test-$target $OUT/$target $TORUN | tee $OUT/$target/run.out | $PROGRESS i
	else
	    count=$(echo $(echo $TORUN | wc -w))
	    printf "$count ${YELLOW}skipped${NORM}\n"
	fi
    fi
}

function execute_tests() {
    for target in $TEST_TARGETS; do
	if [ "$target" = "int" ]; then
	    execute_int_tests "int" ""
	    execute_int_tests "int-ra" "-ra"
	    execute_int_tests "int-ra-ma" "-ra -ma"
	elif [[ "$target" = "jvm" || "$target" = "jar" ]]; then
            compile_target_tests jvm -jvm.script=false
            execute_target_tests jvm
	    continue
	else
	    compile_target_tests $target
	    execute_target_tests $target
	fi
    done
}

function set_os_sources() {
    target=$1
    if [ "$target" = "x86-darwin" ]; then
	export OS_SOURCES="$RT_LOC/x86-darwin/*.v3"
    elif [ "$target" = "x86-64-darwin" ]; then
	export OS_SOURCES="$RT_LOC/x86-64-darwin/*.v3"
    elif [ "$target" = "x86-linux" ]; then
	export OS_SOURCES="$RT_LOC/x86-linux/*.v3"
    elif [ "$target" = "x86-64-linux" ]; then
	export OS_SOURCES="$RT_LOC/x86-64-linux/*.v3"
    fi
}

function compile_aeneas() {
    local HOST_AENEAS=$1
    local TARGET_DIR=$2/$3
    local target=$3
    mkdir -p $TARGET_DIR
    if [ "$QUIET_COMPILE" != 1 ]; then
	echo "${CYAN}Compiling ($HOST_AENEAS -> $TARGET_DIR/Aeneas)...${NORM}"
    fi

    pushd ${VIRGIL_LOC} > /dev/null
    local SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
    CMD=bin/v3c-$target
    if [ ! -x $CMD ]; then
	CMD=bin/dev/v3c-$target
    fi
    V3C=$HOST_AENEAS $CMD $V3C_HEAP_SIZE $V3C_OPTS -fp -jvm.script -jvm.args="$AENEAS_JVM_TUNING" -output=$TARGET_DIR $SRCS
    EXIT_CODE=$?
    popd > /dev/null
    if [ $EXIT_CODE != 0 ]; then
	exit $EXIT_CODE
    fi
    if [ "$QUIET_COMPILE" != 1 ]; then
	wc -c $TARGET_DIR/* | sed 's/^/  /'
    fi
}
