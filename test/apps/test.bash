#!/bin/bash

. ../common.bash apps

# Test that each of the applications actually compiles
cd ../../apps
APPS=$(ls */*.v3 | cut -d/ -f1 | uniq)

target=$TEST_TARGET

function do_app() {
  printf "  Compiling ($target) %s..." $1
  local out=$OUT/$1.compile.out
  run_v3c $target -output=$OUT $1/*.v3 &> $out
  check $?
}

for b in $APPS; do
  do_app $b
done
