#/bin/bash

. ../common.bash gc

if [ $# -gt 0 ]; then
  ALL_TESTS="$*"
else
  ALL_TESTS=$(cat *.gc)
fi

function set_rt_files() {
    target=$1
    N="$RT_LOC/native/"
    GC_SOURCES="${GC_LOC}/*.v3"

    if [ "$target" = "x86-darwin" ]; then
	export RT_FILES="$RT_LOC/x86-darwin/*.v3 $N/*.v3 $GC_SOURCES ./TagUtils.v3"
    elif [ "$target" = "x86-64-darwin" ]; then
	export RT_FILES="$RT_LOC/x86-64-darwin/*.v3 $N/*.v3 $GC_SOURCES ./TagUtils.v3"
    elif [ "$target" = "x86-linux" ]; then
	export RT_FILES="$RT_LOC/x86-linux/*.v3 $N/*.v3 $GC_SOURCES ./TagUtils.v3"
    elif [ "$target" = "x86-64-linux" ]; then
	export RT_FILES="$RT_LOC/x86-64-linux/*.v3 $N/*.v3 $GC_SOURCES ./TagUtils.v3"
    elif [ "$target" = "arm64-linux" ]; then
	export RT_FILES="$RT_LOC/arm64-linux/*.v3 $N/*.v3 $GC_SOURCES ./TagUtils.v3"
    elif [ "$target" = "wasm" ]; then
	export RT_FILES="./EmptySystem.v3 $N/NativeGlobalsScanner.v3 $N/NativeFileStream.v3 $GC_SOURCES ./TagUtils.v3"
    fi
}


function compile_gc_tests() {
    local SHARDING=80
    local target=$1
    shift

    # The 4k shadow stack is sized for the micro tests indexed by the other .gc
    # files. The test/smoke tests are medium-sized by design and recurse deeper,
    # so they are compiled in a separate shard with more shadow stack; the
    # per-test //@heap-size directive overrides -heap-size for both shards.
    local micro="" smoke=""
    for t in "$@"; do
	case "$t" in
	    ../smoke/*) smoke="$smoke $t" ;;
	    *)          micro="$micro $t" ;;
	esac
    done

    RT_OPT="-rt.files=$(echo $RT_FILES)"
    compile_gc_shard "$target" 4k $micro
    compile_gc_shard "$target" 256k $smoke
}

function compile_gc_shard() {
    local SHARDING=80
    local target=$1
    local sstack=$2
    shift 2
    if [ $# = 0 ]; then
	return 0
    fi

    local i=1
    while [ $i -le $# ]; do
	local args=${@:$i:$SHARDING}
	run_v3c "" -symbols -output=$T -target=$target-test -tr -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -shadow-stack-size=$sstack -heap-size=10k "$RT_OPT" -multiple $args
	i=$(($i + $SHARDING))
    done
}

function do_int_test() {
    T=$OUT/$target
    mkdir -p $T
    ALL=$T/compile.all.out
    rm -f $ALL

    # TODO: factor out helper function for is64 into common.bash
    if [[ "$target" =~ "x86-64" || "$target" =~ "arm64" ]]; then
        HEAP='-heap-size=65m' # 64-bit needs more heap
    else
        HEAP='-heap-size=32m'
    fi

    BEFORE=$V3C_OPTS
    V3C_OPTS="$V3C_OPTS $HEAP -shadow-stack-size=1m"
    QUIET_COMPILE=1
    compile_aeneas $AENEAS_TEST $OUT $target
    V3C_OPTS="$BEFORE"

    print_status Testing "$target $HEAP" Aeneas
    if [ -x $CONFIG/run-$target ]; then
	$T/Aeneas -test -ra $VIRGIL_LOC/test/core/*.v3 | tee $T/Aeneas-gc.test.out | $PROGRESS
        fail_fast
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

function do_exe_test() {
    set_rt_files $target
    T=$OUT/$target
    mkdir -p $T
    C=$T/compile.out
    ALL=$T/compile.all.out
    rm -f $ALL

    print_compiling "$target" ""
    compile_gc_tests $target $TESTS | tee $T/compile.all.out | $PROGRESS
    fail_fast

    execute_target_tests $target
    fail_fast
}

function get_target_tests() {
    TAGGED_REF64_PATTERN="taggedRef.*_64.v3"
    TAGGED_REF32_PATTERN="taggedRef.*_32.v3"
    if [ "$target" = wasm ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF64_PATTERN)
    elif [ "$target" = x86-linux ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF64_PATTERN)
    elif [ "$target" = x86-darwin ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF64_PATTERN)
    elif [ "$target" = x86-64-linux ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF32_PATTERN)
    elif [ "$target" = x86-64-darwin ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF32_PATTERN)
    elif [ "$target" = arm64-linux ]; then
        TESTS=$(ls $ALL_TESTS | grep -E -v $TAGGED_REF32_PATTERN)
    else
        TESTS=$ALL_TESTS
    fi
}

for target in $TEST_TARGETS; do
    get_target_tests 
    is_gc_target $target && do_exe_test || do_nothing
done

for target in $(get_io_targets); do
    get_target_tests 
    is_gc_target $target && do_int_test || do_nothing
done
