#/bin/bash

. ../common.bash gc

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(cat *.gc)
fi

function set_rt_files() {
    target=$1
    N="$RT_LOC/native/"
    GC_SOURCES="${GC_LOC}/*.v3"

    if [ "$target" = "x86-darwin" ]; then
	export RT_FILES="$RT_LOC/x86-darwin/*.v3 $N/*.v3 $GC_SOURCES"
    elif [ "$target" = "x86-64-darwin" ]; then
	export RT_FILES="$RT_LOC/x86-64-darwin/*.v3 $N/*.v3 $GC_SOURCES"
    elif [ "$target" = "x86-linux" ]; then
	export RT_FILES="$RT_LOC/x86-linux/*.v3 $N/*.v3 $GC_SOURCES"
    elif [ "$target" = "x86-64-linux" ]; then
	export RT_FILES="$RT_LOC/x86-64-linux/*.v3 $N/*.v3 $GC_SOURCES"
    elif [ "$target" = "wasm" ]; then
	export RT_FILES="./EmptySystem.v3 $N/NativeGlobalsScanner.v3 $N/NativeFileStream.v3 $GC_SOURCES"
    fi
}


function compile_gc_tests() {
    local SHARDING=80
    local target=$1
    shift

    local i=1
    RT_OPT="-rt.files=$(echo $RT_FILES)"
    while [ $i -le $# ]; do
	local args=${@:$i:$SHARDING}
	run_v3c "" -symbols -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -shadow-stack-size=4k -heap-size=10k "$RT_OPT" -multiple $args
	i=$(($i + $SHARDING))
    done
}

function do_int_test() {
    T=$OUT/$target
    mkdir -p $T
    ALL=$T/compile.all.out
    rm -f $ALL

    if [[ "$target" =~ "x86-64" ]]; then
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

for target in $TEST_TARGETS; do
    is_gc_target $target && do_exe_test || do_nothing
done

for target in $(get_io_targets); do
    is_gc_target $target && do_int_test || do_nothing
done
