#!/bin/bash
SOURCE=${BASH_SOURCE[0]}
HERE=$(command dirname $SOURCE)
. $HERE/funcs.bash
# set DIR to true location of this file
follow_links $SOURCE

VIRGIL_LOC=$DIR/../..
TEST_DIR=$VIRGIL_LOC/test

$TEST_DIR/configure

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_TARGETS="wasm-js" $TEST_DIR/all.bash
