#!/bin/bash

. ../common.bash apps

# Test that each of the applications actually compiles
cd ../../apps
APPS=$(ls */*.v3 | cut -d/ -f1 | uniq)

target=$TEST_TARGET

function do_app() {
  printf "  Compiling ($target) %s..." $1
  cd $1
  local out=$OUT/$1.compile.out
  local deps=""
  if [ -f DEPS ]; then
    deps=$(cat DEPS)
  fi
  run_v3c "$target" -output=$OUT *.v3 $deps &> $out
  check $?
  cd ..
}

for b in $APPS; do
  do_app $b
done
