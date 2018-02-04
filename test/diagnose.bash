#!/bin/bash

debug=1
jvm=0
wasm=0

if [ "-d" = "$1" ]; then
	debug=1
	shift
fi

if [ "-jvm" = "$1" ]; then
	jvm=1
	shift
fi

if [ "-wasm" = "$1" ]; then
	wasm=1
	shift
fi

if [ $# != 1 ]; then
	echo "Usage: diagnose.bash <one test>"
        exit 1
fi

if [ "$AENEAS_TEST" = "" ]; then
    AENEAS_TEST=$V3C_DEV
fi

function execute() {
	[ $debug = 1 ] && echo % $@
	$@
}

function line() {
    echo ================================================================================
}

T="/tmp/$USER/virgil-test/diagnose/"
execute mkdir -p $T

line
execute cat $*
exec_v3c="execute $V3C_DEV $V3C_OPTS"

tests=$1
test=${1%*.*}

if [ "$jvm" = 1 ]; then
    rtpath=$VIRGIL_LOC/rt/jvm/bin
    line
    execute $AENEAS_TEST $V3C_OPTS -target=jvm-test -jvm.rt-path=$rtpath -output=$T -print-ssa $tests | tee $T/$test.compile.jvm.out
    line
    execute java -classpath $rtpath:$T V3S_Tester $tests | tee $T/$test.run.jvm.out
elif [ "$wasm" = 1 ]; then
    line
    execute $AENEAS_TEST $V3C_OPTS -target=wasm-js-test -output=$T -print-mach -print-ssa $tests | tee $T/$test.compile.wasm.out
    line
    execute cd $T
    execute $TEST_D8 --trace-wasm-decoder $VIRGIL_LOC/test/wasm-js-tester.js -- $tests | tee $T/$test.run.wasm.out
    
fi
