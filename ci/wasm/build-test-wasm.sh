#!/bin/bash
SOURCE=${BASH_SOURCE[0]}
HERE=$(command dirname $SOURCE)
. $HERE/funcs.bash
DIR=$(cd -P $HERE && pwd)

VIRGIL_LOC=$DIR/../..
TEST_DIR=$VIRGIL_LOC/test

$TEST_DIR/configure

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_TARGETS="wasm" $TEST_DIR/all.bash
