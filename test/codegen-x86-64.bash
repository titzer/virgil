#!/bin/bash

# XXX: compile aeneas to tmp directory
aeneas bootstrap

if [ $? != 0 ]; then
    exit 1
fi

DIRS="execute fsi32 fsi64 legacy_intcast future_intcast variants enums pointer large float"

if [ $# != 0 ]; then
    DIRS="$@"
fi

for d in $DIRS; do
    echo --- $d ---------
    (cd $d; RUN_WASM=0 RUN_JVM=0 RUN_INT=0 RUN_NATIVE=0 RUN_X86_64=1 ./test.bash)
done
