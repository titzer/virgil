#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)

export TEST_KIND=exe
export TARGET=$1
shift

export OUT=/tmp/$USER/virgil-test/$TARGET/exe
mkdir -p $OUT

export RUNNERS=$(builtin cd $VIRGIL_TEST/config && echo test-${TARGET}*)
if [ "$RUNNERS" = "test-${TARGET}*" ]; then
    echo No runners for $TARGET, skipping.
    exit 0
else
    for runner in $RUNNERS; do
	$VIRGIL_TEST/config/$runner $OUT "$@"
    done
fi
