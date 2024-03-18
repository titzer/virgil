#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)

export V3C_OPTS="$V3C_OPTS -set-exec=false"
exec $VIRGIL_TEST/scripts/run-exe-common.bash jvm "$@"
