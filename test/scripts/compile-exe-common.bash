#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)
VIRGIL_LOC=${VIRGIL_LOC:=$(builtin cd $VIRGIL_TEST/.. && pwd)}
AENEAS_TEST=${AENEAS_TEST:=$VIRGIL_LOC/bin/v3c}

export TEST_KIND=exe
export TARGET=$1
shift

export OUT=/tmp/$USER/virgil-test/$TARGET/exe
mkdir -p $OUT

C=$OUT/compile.out

exec $AENEAS_TEST $V3C_OPTS -target=${TARGET}-test -multiple -output=$OUT "$@" | tee $C
