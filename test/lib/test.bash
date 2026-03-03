#!/usr/bin/env bash

. ../common.bash lib

let PROGRESS_PIPE=1
if [[ "$1" =~ "-trace-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [[ "$1" =~ "-fatal-calls=" ]]; then
    V3C_OPTS="$1 $V3C_OPTS"
    shift
    let PROGRESS_PIPE=0
fi

if [ "$1" = "-fatal" ]; then
    FATAL="-fatal"
    shift
fi

if [ $# -gt 0 ]; then
  TESTS=$*
else
  TESTS=*.v3
fi

LIB_FILES="$VIRGIL_LOC/lib/util/*.v3 $VIRGIL_LOC/lib/math/*.v3 $VIRGIL_LOC/lib/file/csv/*.v3 $VIRGIL_LOC/lib/file/json/*.v3"

function do_v3i() {
    P=$OUT/run.out
    run_v3c "" $TESTS $LIB_FILES
    if [ "$?" != 0 ]; then
	printf "  %sfail%s: lib tests failed to compile\n" "$RED" "$NORM"
	exit 1
    fi

    if [ "$PROGRESS_PIPE" = 1 ]; then
	print_status Running v3i
	run_v3c "" -run $TESTS $LIB_FILES $FATAL | tee $P | $PROGRESS
	print_status Running "v3i -ra"
	run_v3c "" -ra -run $TESTS $LIB_FILES $FATAL | tee $P | $PROGRESS
    else
	print_status Running v3i
	run_v3c "" -run $TESTS $LIB_FILES $FATAL | tee $P
	print_status Running "v3i -ra"
	run_v3c "" -ra -run $TESTS $LIB_FILES $FATAL | tee $P
    fi
}

function do_compiled() {
    T=$OUT/$target
    mkdir -p $T

    C=$T/compile.out
    R=$OUT/$target/run.out

    print_compiling $target
    # HACK until wasm-gc is in stable
    if [ "$target" = wasm-gc-wasi1 ] && [ -z "${AENEAS_TEST##*/stable/*}" ]; then
	printf "${YELLOW}skipped${NORM}\n"
        return
    fi
    run_v3c $target -output=$T $TESTS $LIB_FILES &> $C
    check_no_red $? $C

    print_status Running $target
    runners=$(get_io_runners $target)
    if [ "$runners" = "" ]; then
        printf "${YELLOW}skipped${NORM}\n"
    else
        for runner in $runners; do
            short="${runner##*/}"
            if [ -x $runner ]; then
                if [ "$short" = "run-wasm-gc-wasi1@node" ]; then
	            $CONFIG/node --no-warnings --experimental-wasi-unstable-preview1 ../../rt/wasm-wasi1-common/wasi.node.mjs $OUT/$target/main.wasm $TESTS | tee $R | $PROGRESS
                else
	            $OUT/$target/main $FATAL $TESTS | tee $R | $PROGRESS
                fi
            else
	        printf "${YELLOW}skipped${NORM}\n"
            fi
            break
        done
    fi
}

for target in $(get_io_targets); do
    if [ "$target" = v3i ]; then
	do_v3i
    else
	do_compiled
    fi
done
