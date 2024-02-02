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

# Progress arguments. By default the inline (i) mode is used, while the CI sets
# it to character (c) mode
PROGRESS_ARGS=${PROGRESS_ARGS:=i}
PROGRESS="${VIRGIL_LOC}/test/config/progress $PROGRESS_ARGS"

XARGS=${XARGS:=0}

AENEAS_TEST=${AENEAS_TEST:=$VIRGIL_LOC/bin/v3c}
TEST_TARGETS=${TEST_TARGETS:="v3i jvm wasm-js x86-linux x86-64-linux x86-darwin x86-64-darwin"}

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

# Runs tests in ./parser/*.v3
function do_parser_tests() {
    cd parser
    print_status Parser ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    # TODO: accumulate errors and continue?
    fail_fast
    cd ..
}

# Runs tests in ./seman/*.v3
function do_seman_tests() {
    cd seman
    print_status Semantic ""
    run_v3c "" -test -expect=failures.txt *.v3 | tee $OUT/out | $PROGRESS
    # TODO: accumulate errors and continue?
    fail_fast
    cd ..
}

function fail_fast() {
    local code="$?"
    if [ "$code" != 0 ]; then
	exit $code
    fi
}

function run_io_test() {
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

    local P=$T/$(basename $test)

		infile=${test##*/}.in
    if [ -f $infile ]; then
			V3C=$AENEAS_TEST $runner $T $test $args < $infile > $P.out 2> $P.err
    elif [ -f $test.in ]; then
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
		if [ -f failures.$target ]; then
		    grep $test failures.$target
		    if [ $? = 0 ]; then
			continue # test was found in expected failures
		    fi
		fi
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
    local runner=$1
    shift
    trace_test_count $#
    for t in $@; do
	run_io_test $target $runner $t
    done
}

function run_or_skip_io_tests() {
    local target=$1
    shift

    PREFIX=$CONFIG/run-$target
    local runners=$(echo ${PREFIX}*)

    if [ "$runners" = "${PREFIX}*" ]; then
	runners=$CONFIG/run-$target
	if [[ ! -x $runners ]]; then
	    print_status Running $target
	    echo "${YELLOW}skipped${NORM}"
	    return 0
	fi
    fi

    for runner in $runners; do
	R=$CONFIG/run-
	tname=${runner/$R/}
	print_status Running $tname
	run_io_tests $target $runner $@ | tee $OUT/$target/run-$tname.out | $PROGRESS
    done
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

function run_v3c_multiple() {
    local SHARDING=$1
    shift
    local target=$1
    shift

    if [ "$XARGS" != 0 ]; then
	if [ -z "$target" ]; then
	    xargs echo "$@" | xargs -n$SHARDING $AENEAS_TEST $V3C_OPTS -multiple
	else
            local F=$VIRGIL_LOC/bin/dev/v3c-$target
            if [ ! -x "$F" ]; then
		F=$VIRGIL_LOC/bin/v3c-$target
            fi
	    V3C=$AENEAS_TEST echo "$@" | xargs -n$SHARDING $F $V3C_OPTS -multiple
	fi
	return
    fi

    local i=1
    while [ $i -le $# ]; do

	local args=${@:$i:$SHARDING}

	if [ -z "$target" ]; then
	    $AENEAS_TEST $V3C_OPTS -multiple $args
	else
            local F=$VIRGIL_LOC/bin/dev/v3c-$target
            if [ ! -x "$F" ]; then
		F=$VIRGIL_LOC/bin/v3c-$target
            fi
	    V3C=$AENEAS_TEST $F $V3C_OPTS -multiple $args
	fi
	i=$(($i + $SHARDING))
    done
}

function execute_v3i_tests() {
    print_status Running "v3i $2 $V3C_OPTS"

    P=$OUT/$1.run.out
    run_v3c "" -test -expect=failures.txt $2 $TESTS | tee $OUT/run.out | $PROGRESS
}

function compile_target_tests() {
    target=$1
    shift
    opts="$@"

    mkdir -p $OUT/$target
    C=$OUT/$target/compile.out
    print_compiling $target
    V3C_OPTS="$V3C_OPTS $opts -set-exec=false -target=$target-test -output=$OUT/$target" run_v3c_multiple 5000 ""  $TESTS | tee $C | $PROGRESS
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
	if [ "$target" = "wasm-spec" ]; then
	   ext=".wasm"
	fi
	check_cached_target_tests $ext | tee $OUT/$target/cached.out | $PROGRESS
	TORUN=$(cat $OUT/$target/leftover)
    else
	TORUN="$TESTS"
    fi

    if [ "$TORUN" != "" ]; then

	RUNNERS=$(cd $CONFIG && echo test-$target*)

	RAN=0
	for r in $RUNNERS; do
	    runner=$CONFIG/$r
	    if [ -x $runner ]; then
		print_status "  running" "${r/test-$target/}"
		$runner $OUT/$target $TORUN | tee $OUT/$target/run.out | $PROGRESS
		RAN=1
	    fi
	done

	if [ "RAN" = 0 ]; then
	    print_status "  skipped" ""
	    count=$(echo $(echo $TORUN | wc -w))
	    printf "$count ${YELLOW}no runners found${NORM}\n"
	fi
    fi
}

function execute_tests() {
    for target in $TEST_TARGETS; do
	if [ "$target" = "v3i" ]; then
            (execute_v3i_tests "v3i" "") || exit $?
            (execute_v3i_tests "v3i-ra" "-ra -ma=false") || exit $?
            (execute_v3i_tests "v3i-ra-ma" "-ra -ma=true") || exit $?
	elif [[ "$target" = "jvm" || "$target" = "jar" ]]; then
            (compile_target_tests jvm -jvm.script=false) || exit $?
            (execute_target_tests jvm) || exit $?
	    continue
	else
            (compile_target_tests $target) || exit $?
            (execute_target_tests $target) || exit $?
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

function convert_to_io_target() {
    target=$1
    if [ "$target" = "jvm" ]; then
	target=jar
    elif [ "$target" = "wasm-js" ]; then
	target=wave
    elif [ "$target" = "wasm-spec" ]; then
	target=wave
    fi
    echo $target
}

function is_gc_target() {
    if [ "$target" = "x86-darwin" ]; then
	return 0
    elif [ "$target" = "x86-64-darwin" ]; then
	return 0
    elif [ "$target" = "x86-linux" ]; then
	return 0
    elif [ "$target" = "x86-64-linux" ]; then
	return 0
    fi
    return 1
}
