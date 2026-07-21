#!/usr/bin/env bash

. ../common.bash pointer

V3C_OPTS="$V3C_OPTS -lang:descriptors"

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else
#TODO: these don't pass because CiRuntime is not available in tests    do_seman_tests

    TEST_LIST=*.v3
fi

# The gc*.v3 tests check that the collector understands described objects, so they must
# be compiled against the real runtime and collector, unlike the rest of the suite.
function set_rt_files() {
    local target=$1
    if [ -d "$RT_LOC/$target" ]; then
	export RT_FILES="$RT_LOC/$target/*.v3 $RT_LOC/native/*.v3 $GC_LOC/*.v3"
    else
	export RT_FILES=""
    fi
}

function compile_gc_target_tests() {
    local target=$1
    shift

    mkdir -p $OUT/$target
    print_compiling $target "(gc)"
    run_v3c "" -output=$OUT/$target -target=$target-test -set-exec=false \
	    -rt.gc -rt.gctables -rt.sttables -shadow-stack-size=4k \
	    "-rt.files=$(echo $RT_FILES)" -multiple "$@" \
	| tee $OUT/$target/compile-gc.out | $PROGRESS
}

LAST=0
for target in $TEST_TARGETS; do
    # filter out any expected failures for the target
    expected="failures.$target"
    if [ -f "$expected" ]; then
	TESTS=$(ls $TEST_LIST | grep -v -f "$expected")
    else
	TESTS=$TEST_LIST
    fi

    if [ "$target" = v3i ]; then
	continue # skip because not native target
    elif [[ "$target" = jvm || "$target" = jar ]]; then
	continue # skip because not native
    elif [ "$target" = wasm ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = wasm-gc ]; then
        continue # skip because only certain operations work
    elif [ "$target" = x86-linux ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = x86-darwin ]; then
	TESTS=$(ls $TESTS | grep -v _64.v3)
    elif [ "$target" = x86-64-linux ]; then
	TESTS=$(ls $TESTS | grep -v _32.v3)
    elif [ "$target" = x86-64-darwin ]; then
	TESTS=$(ls $TESTS | grep -v _32.v3)
    else
	continue;
    fi

    ALL_TESTS=$TESTS
    GC_TESTS=$(echo "$ALL_TESTS" | tr ' ' '\n' | grep '^gc')
    TESTS=$(echo "$ALL_TESTS" | tr ' ' '\n' | grep -v '^gc')

    compile_target_tests $target

    if [ "$GC_TESTS" != "" ]; then
	set_rt_files $target
	compile_gc_target_tests $target $GC_TESTS
    fi

    TESTS=$ALL_TESTS
    execute_target_tests $target
    LAST=$?
done

exit $LAST
