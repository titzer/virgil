#!/bin/bash

. ../common.bash apps

# Test that each of the applications actually compiles
cd ../../apps
APPS=$(ls */*.v3 | cut -d/ -f1 | uniq)

target=$TEST_TARGET

function compile_apps() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	cd $VIRGIL_LOC/apps/$t
	local deps=""
	if [ -f TARGETS ]; then
	    if [ "$target" = "" ]; then
		echo ${YELLOW}skip${NORM}
		echo "##-ok"
		continue
	    fi
	    grep -q $target TARGETS > /dev/null
	    if [ $? != 0 ]; then
		echo ${YELLOW}skip${NORM}
		echo "##-ok"
		continue
	    fi
	fi
	if [ -f DEPS ]; then
	    deps=$(cat DEPS)
	fi
	run_v3c "$target" -output=$OUT *.v3 $deps
	trace_test_retval $?
    done
}

print_status Compiling $target
compile_apps $APPS | tee $OUT/compile.out | $PROGRESS i
