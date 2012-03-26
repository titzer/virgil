#!/bin/bash

. ../common.bash bench

# Test that each of the benchmarks actually compiles
cd ../../bench

if [ $# != 0 ]; then
  BENCHMARKS="$*"
else
  BENCHMARKS=$(ls */*.v3 | cut -d/ -f1)
fi

target=$TEST_TARGET
T=$OUT/$target
mkdir -p $T

function do_benchmark() {
  printf "  Compiling ($target) %s..." $1
  local out=$T/$1.compile.out
  run_v3c $target -output=$T Common.v3 $1/$1.v3 &> $out
  local ok=$?
  check $ok
  if [ $ok = 0 ]; then
     if [[ -f $1/output-test && -x $T/$1 ]]; then
	run_io_test $target $1 "$(cat $1/args-test)" $1/output-test
     fi
  fi

}

for b in $BENCHMARKS; do
  do_benchmark $b
done
