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

  print_compiling "$target" "$tests"
  TESTS=$(ls $T/*.st)

  C=$T/compile.out
  ALL=$T/compile.all.out

  for f in $TESTS; do
    # TODO: compile multiple tests at once with Aeneas
    fname="${basedir}$(basename $f)"
    fname="${fname%*.*}.v3"
    run_v3c "" -output=$T -target=$target-test -rt.sttables $fname $RT_SOURCES >> $C

    grep '31m' $C > $C.error
    if [ $? == 0 ]; then
	printf "${RED}failed${NORM}\n"
	cat $C.error
	exit 1
    fi
    cat $C >> $ALL
  done

  printf "${GREEN}ok${NORM}\n"

  if [ "$RUN_NATIVE" != 0 ]; then
      run_native $target $TESTS
  fi
}

tests=$(ls *.v3)

print_status Testing int "test/stacktrace/*.v3"
run_v3c "" -test -test.st -output=$T $tests &> $P
check_red $P

for t in $(ls *.st); do
  print_status Checking "" "$t"
  diff $t $T/$t &> $T/$t.diff
  check $?  
done

target=$TEST_TARGET
if [[ "$target" != x86-darwin && "$target" != x86-linux ]]; then
    print_status Skipping "$target/$HOST_PLATFORM"
    echo "${YELLOW}ok${NORM}"
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

print_status Testing int "$tests"
run_v3c "" -test -test.st -output=$T $TESTS $> $T/test
check_red $T/test

do_test ../execute/ $tests