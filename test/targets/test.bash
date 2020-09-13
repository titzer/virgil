#!/bin/bash

. ../common.bash targets

mkdir -p $OUT

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

# test the interpreter first
function run_interpreter() {
    for test in $TESTS; do
        local expect=$test.expect
        local out=$OUT/$test.out
        
        printf "  Running      (int) ${test}..."
        run_v3c "" -run $test > $out
        diff $expect $out > /dev/null
        check $?
    done
}

run_interpreter

function run_target() {
    local target=$1
    
    for test in $TESTS; do
        local expect=$test.expect
        local T=$OUT/$target
        mkdir -p $T
        print_compiling "$target" $test
        local out=$T/$1.compile.out
        run_v3c $target -output=$T $test &> $out
        local ok=$?
        check $ok
        
        bin="$(echo $test | sed -es/.v3\$//g)"
        run_io_test $target $bin "" $expect
	check $?
    done
}

targets="x86-darwin-nort x86-darwin-nogc x86-darwin x86-linux-nort x86-linux-nogc x86-linux jar wave wave-nogc"
for target in $targets; do
    run_target $target
done
