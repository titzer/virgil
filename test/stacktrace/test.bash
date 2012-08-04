#!/bin/bash

. ../common.bash stacktrace

target=$TEST_TARGET
T=$OUT/$target
mkdir -p $T
P=$T/test.out
C=$T/$target-test.compile.out
rm -f $C $P
rm -f $T/*.st

if [ "$target" == x86-darwin ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/darwin/*.v3"
elif [ "$target" == x86-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/linux/*.v3"
fi

function do_test() {
  basedir=$1
  tests=$2

  printf "  Compiling ($target) $tests..."
  ST_TESTS=$(ls $T/*.st)
  for f in $ST_TESTS; do
    # TODO: compile multiple tests at once with aeneas
    fname="${basedir}$(basename $f)"
    fname="${fname%*.*}.v3"
    run_v3c "" -output=$T -target=$target-test -rt.sttables $fname $RT_SOURCES >> $C
  done
  check_no_red $? $C

  run_native stacktrace $target $ST_TESTS
}

tests=$(ls *.v3)

printf "  Testing   (int) test/stacktrace/*.v3..."
run_v3c "" -test -test.st -output=$T $tests &> $P
check_red $P

for t in $(ls *.st); do
  printf "  Checking  $t..."
  diff $t $T/$t &> $T/$t.diff
  check $?  
done

target=$TEST_TARGET
if [[ "$target" != x86-darwin && "$target" != x86-linux ]]; then
    echo "  Skipping  ($target/$HOST_PLATFORM)...${YELLOW}ok${NORM}"
    exit 0
fi

do_test '' 'test/stacktrace/*.v3'

rm -f $T/*.st
if [ $# -gt 0 ]; then
  TESTS="$*"
  tests='tests'
else
  TESTS=$(ls ../execute/*.v3)
  tests='test/execute/*.v3'
fi

printf "  Testing   (int) $tests..."
run_v3c "" -test -test.st -output=$T $TESTS $> $T/test
check_red $T/test

do_test ../execute/ $tests