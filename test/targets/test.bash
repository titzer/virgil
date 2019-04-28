#!/bin/bash

. ../common.bash targets

mkdir -p $OUT

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

function compile_test() {
    test=$1

    local expect=$test.expect
    local out=$OUT/$test.out
    
    # test the interpreter first
    printf "  Running      (int) ${test}..."
    run_v3c "" -run $test > $out
    diff $expect $out > /dev/null
    check $?

    local targets="x86-darwin x86-linux jar wave"
    for target in $targets; do
        local T=$OUT/$target
        mkdir -p $T
        print_compiling "$target" $1
        local out=$T/$1.compile.out
        run_v3c $target -output=$T $test &> $out
        local ok=$?
        check $ok

        bin="$(echo $test | sed -es/.v3\$//g)"
	run_io_test $target $bin "" $expect
    done
}

for t in $TESTS; do
    compile_test $t
done
