#!/usr/bin/env bash

. ../common.bash darwin

chmod 444 readonly.txt

# Tests live in a subdirectory per target. The two darwin ABIs share nothing:
# the 32-bit tests use bare syscall numbers, which raise SIGSYS on x86-64, and
# 32-bit struct layouts. Test programs run with this directory as the working
# directory, so the fixtures (test.txt, readonly.txt, writable.txt) stay here.

function do_test() {
    print_compiling "$target"
    mkdir -p $OUT/$target
    run_v3c "" -multiple -set-exec=false -target=$target-test -output=$OUT/$target $TESTS | tee $OUT/compile.out | $PROGRESS

    execute_target_tests $target
}

# Kernel tests are C programs that issue raw system calls. They check what the
# kernel itself does, independent of the Virgil compiler and runtime.
CC=${CC:=cc}

function run_kernel_tests() {
    trace_test_count $#
    for t in $@; do
	local exe=$OUT/$target/kernel/$(basename $t .c)
	trace_test_start $t
	$CC -arch x86_64 -o $exe $t > $exe.out 2>&1 && $exe >> $exe.out 2>&1
	trace_test_retval $? $exe.out
    done
}

function do_kernel_test() {
    print_status "Kernel" "$target"
    local runners=$(cd $CONFIG && echo test-$target*)
    if [[ "$runners" = "test-$target*" || -z "$(which $CC)" ]]; then
	# this host cannot run (or cannot compile) native programs for the target
	printf "${YELLOW}skipped${NORM}\n"
	return 0
    fi
    mkdir -p $OUT/$target/kernel
    run_kernel_tests $KERNEL_TESTS | tee $OUT/$target/kernel/run.out | $PROGRESS
}

for target in $TEST_TARGETS; do
    if [ ! -d "$target" ]; then
	continue
    fi
    if [ $# == 0 ]; then
	ALL=$(ls $target/*.v3 $target/*.c 2> /dev/null)
    else
	ALL=$(echo "$@" | tr ' ' '\n' | grep "^$target/")
    fi
    TESTS=$(echo "$ALL" | grep '\.v3$')
    KERNEL_TESTS=$(echo "$ALL" | grep '\.c$')
    if [ -n "$TESTS" ]; then
	do_test
    fi
    if [ -n "$KERNEL_TESTS" ]; then
	do_kernel_test
    fi
done
