#!/bin/bash

export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)

. $VIRGIL_TEST/scripts/run-exe-common.bash x86-linux "$@"


