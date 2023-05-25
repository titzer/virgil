#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

if [ "$#" -gt 0 ]; then
    # first argument is (single) test target
    export TEST_TARGETS=$1
    shift
else
    # skip the interpreter tests
    export TEST_TARGETS="wasm-js x86-darwin x86-linux x86-64-linux"
fi

if [ "$#" -gt 0 ]; then
    # rest of the arguments are the test directories to run
    DIRS="$@"
else
    # TODO: ptr32 and ptr64
    # TODO: skip parse and seman tests for these directories
    DIRS="execute fsi32 fsi64 cast float variants enums large"
fi

export SKIP_BOOTSTRAP=1
export QUIET_SETUP=1
export QUIET_COMPILE=1

$DIR/all.bash $DIRS
