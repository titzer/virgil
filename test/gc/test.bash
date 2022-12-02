#/bin/bash

. ../common.bash gc

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(cat core.gc variants.gc large.gc)
fi

function compile_gc_tests() {
    local SHARDING=100
    local target=$1
    shift

    RT_FILES="-rt.files=$(echo $OS_SOURCES $NATIVE_SOURCES $GC_SOURCES)"
    local i=1
    while [ $i -le $# ]; do
	local args=${@:$i:$SHARDING}
	run_v3c "" -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -heap-size=10k "$RT_FILES" -multiple $args
	i=$(($i + $SHARDING))
    done
}

function do_test() {
    set_os_sources $target
    T=$OUT/$target
    mkdir -p $T
    C=$T/compile.out
    ALL=$T/compile.all.out
    rm -f $ALL

    print_compiling "$target" ""
    compile_gc_tests $target $TESTS | tee $T/compile.all.out | $PROGRESS $PROGRESS_ARGS

    execute_target_tests $target

    if [[ "$target" =~ "x86-64" ]]; then
        HEAP='-heap-size=48m' # 64-bit needs more heap
    else
        HEAP='-heap-size=24m'
    fi
    BEFORE=$V3C_OPTS
    V3C_OPTS="$V3C_OPTS $HEAP"
    QUIET_COMPILE=1
    compile_aeneas $AENEAS_TEST $T $target
    V3C_OPTS="$BEFORE"

    print_status Testing "$target $HEAP" Aeneas
    if [ -x $CONFIG/run-$target ]; then
	$T/$target/Aeneas -test -rma $VIRGIL_LOC/test/core/*.v3 | tee $T/$target/Aeneas-gc.test.out | $PROGRESS $PROGRESS_ARGS
    else
	echo "${YELLOW}skipped${NORM}"
    fi
}

for target in $TEST_TARGETS; do
    # TODO: gc tests for wasm
    if [ "$target" = "x86-darwin" ]; then
	do_test
    elif [ "$target" = "x86-64-darwin" ]; then
	do_test
    elif [ "$target" = "x86-linux" ]; then
	do_test
    elif [ "$target" = "x86-64-linux" ]; then
	do_test
    fi
done
