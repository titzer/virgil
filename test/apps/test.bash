#!/bin/bash

. ../common.bash apps

# Test that each of the applications actually compiles
cd ../../apps
APPS=$(ls */*.v3 | cut -d/ -f1 | uniq)

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
	run_v3c "$target" -output=$T *.v3 $deps
	trace_test_retval $?
    done
}

for target in $TEST_TARGETS; do
    if [ "$target" = int ]; then
	continue
    fi
    target=$(convert_to_io_target $target)

    T=$OUT/$target
    mkdir -p $T
    print_status Compiling $target
    compile_apps $APPS | tee $T/compile.out | $PROGRESS
done
