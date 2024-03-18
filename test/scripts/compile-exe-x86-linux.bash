#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)

exec $VIRGIL_TEST/scripts/compile-exe-common.bash x86-linux "$@"
