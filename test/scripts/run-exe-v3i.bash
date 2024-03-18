#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)
VIRGIL_LOC=${VIRGIL_LOC:=$(builtin cd $VIRGIL_TEST/.. && pwd)}
AENEAS_TEST=${AENEAS_TEST:=$VIRGIL_LOC/bin/v3c}

export TEST_KIND=exe
export TARGET=int

export OUT=/tmp/$USER/virgil-test/$TARGET/exe
mkdir -p $OUT

R=$OUT/run.out

exec $AENEAS_TEST -test -multiple "$@" | tee $R
