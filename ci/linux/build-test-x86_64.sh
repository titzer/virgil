#!/bin/bash
SOURCE=${BASH_SOURCE[0]}
HERE=$(command dirname $SOURCE)
. $HERE/funcs.bash
# set DIR to true location of this file
follow_links $SOURCE

VIRGIL_LOC=$DIR/../..
TEST_DIR=$VIRGIL_LOC/test

echo "Install nasm"
sudo apt -y install nasm

$TEST_DIR/configure

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_TARGETS="v3i x86-64-linux" "$TEST_DIR"/all.bash
