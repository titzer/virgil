#!/bin/bash

. ../common.bash system

function do_test() {
    params="$2"
    exp="$3"
    local expect=$T/$1.expect
    local out=$T/$1.out
    rm -f $out $expect
    if [ "$exp" = "" ]; then touch $expect
    else printf "$exp" > $expect
    fi
    trace_test_start $1
    if [ $int = 0 ]; then
	run_io_test $target "${1%*.*}" "$params" "$expect"
    else
	run_v3c "" -run $1 $params > $out
	diff $expect $out
    fi
    trace_test_retval $?
}

function run_sys_tests() {
    if [[ $int = 0 && ! -x $CONFIG/run-$target ]]; then
	echo "${YELLOW}skipped${NORM}"
    else
	do_tests | tee $T/run.out | $PROGRESS i
    fi
}

function do_tests() {

do_test System_putc1.v3 "" "System.putc\n"
if [ "$target" != jar ] && [ "$target" != wave ]; then    # TODO
do_test System_error1.v3 "" "!SystemError: with a message
	in System_error1.main() [System_error1.v3 @ 3:29]\n\n"
do_test System_error2.v3 "" "!SystemError: with a message
	in System_error2.main() [System_error2.v3 @ 4:18]\n\n"
do_test System_error3.v3 "" "!SystemError: with a message
	in System_error3.foo() [System_error3.v3 @ 7:29]
	in System_error3.main() [System_error3.v3 @ 3:20]\n\n"
do_test System_error4.v3 "" "!SystemError: with a message
	in System_error4.foo3() [System_error4.v3 @ 9:29]
	in System_error4.foo2() [System_error4.v3 @ 7:26]
	in System_error4.foo1() [System_error4.v3 @ 6:26]
	in System_error4.main() [System_error4.v3 @ 3:21]\n\n"
fi
do_test System_fileClose1.v3 "" ""
if [ "$target" != wave ]; then # TODO
do_test System_fileLeft1.v3 "" "32"
fi
do_test System_fileLoad1.v3 "" "32"
do_test System_fileOpen1.v3 "" "success"
do_test System_fileRead1.v3 "" "success"
do_test System_fileRead2.v3 "" "32"
do_test System_fileReadK0.v3 "" "success"
do_test System_fileReadK1.v3 "" "success"
do_test System_fileWrite0.v3 "" "stdout"
do_test System_fileWrite1.v3 "" ""
do_test System_putc1.v3 "" "System.putc\n"
do_test System_putc2.v3 "" "System.putc\n"
do_test System_puti1.v3 "" "0-11200-21474836482147483647"
do_test System_puti2.v3 "" "0-11200-21474836482147483647"
do_test System_puts1.v3 "" "System.puts\n"
do_test System_puts2.v3 "" "System.puts\n"
do_test System_ln1.v3 "" "System.ln\n"
do_test System_ticksMs1.v3 "" "success"
do_test System_ticksUs1.v3 "" "success"
do_test System_ticksNs1.v3 "" "success"
do_test Params01.v3 "a bakedFDA c -def" "0:a 1:bakedFDA 2:c 3:-def"
do_test Params02.v3 "" ""
do_test Params02.v3 "a b c" ""

# TODO: these tests fail because of an extra stack frame
if [ "$target" = "int" ]; then
do_test System_fileWriteK_null1.v3 "" "!NullCheckException
	in main() [System_fileWriteK_null1.v3 @ 4:26]\n\n"
do_test System_fileWriteK_oob1.v3 "" "!BoundsCheckException
	in main() [System_fileWriteK_oob1.v3 @ 4:26]\n\n"
do_test System_fileWriteK_oob2.v3 "" "!BoundsCheckException
	in main() [System_fileWriteK_oob2.v3 @ 4:26]\n\n"
do_test System_fileWriteK_oob3.v3 "" "!BoundsCheckException
	in main() [System_fileWriteK_oob3.v3 @ 4:26]\n\n"
fi
}

if [ $# -gt 0 ]; then
  TESTS=$*
else
  TESTS=*.v3
fi

for target in $TEST_TARGETS; do
    int=0
    if [ "$target" = "int" ]; then
	int=1
	T=$OUT/$target
	mkdir -p $T
	print_status Running $target
	do_tests | tee $T/run.out | $PROGRESS i
	continue
    elif [ "$target" = "wasm-js" ]; then
	target=wave
    elif [ "$target" = "jvm" ]; then
	target=jar
    fi

    # compile+run
    T=$OUT/$target
    mkdir -p $T

    print_status Compiling $target
    run_v3c $target -output=$T -multiple $TESTS | tee $T/compile.out | $PROGRESS i
    print_status Running $target
    run_sys_tests
done
