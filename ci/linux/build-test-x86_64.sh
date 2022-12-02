#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

source "${DIR}/../../test/common.bash"

${VIRGIL_LOC}/test/configure
export PATH=$PATH:"${VIRGIL_LOC}/bin:${VIRGIL_LOC}/bin/dev"

PROGRESS_ARGS=l TEST_TARGETS="int x86-64-linux" aeneas test
