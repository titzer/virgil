#!/bin/bash

LOC=$(dirname ${BASH_SOURCE[0]})

. $LOC/../../common.bash

if [ $# = 0 ]; then
	echo "Usage: diagnose <test.v3>"
	exit 1
fi

TEST=$1

T=${VIRGIL_TEST_OUT}/x86-darwin-test-runner
C=${VIRGIL_TEST_OUT}/x86-darwin-test.compile.out
R=${VIRGIL_TEST_OUT}/x86-darwin-test.run.out

cat $TEST

echo   "---------------------------------------------------"
printf "Executing (-rma -norm-delegates)..."
run_v3c "" -test -rma -norm-delegates $TEST &> $C
check_passed $C

echo   "---------------------------------------------------"
printf "Compiling tests to x86-darwin..."
run_v3c "" -debug-mach -debug-ssa -multiple -target=x86-darwin-test -output=$VIRGIL_TEST_OUT $TEST &> $C
check_passed $C

if [ ! -e $T ] || [ "$(find $LOC -newer $T)" != "" ]; then
	echo   "---------------------------------------------------"
	printf "Compiling runner.c..."
	gcc -o $T $LOC/runner.c
	check $?
fi

echo   "---------------------------------------------------"
printf "Running tests on x86-darwin..."
$T ${VIRGIL_TEST_OUT} $TEST &> $R
code=$?
check $code
if [ $code != 0 ]; then
	cat $C
	cat $R
	fn="$(basename $TEST)"
	fn=${fn%*.*}
	echo "gdb $VIRGIL_TEST_OUT/$fn"
fi
