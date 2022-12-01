#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

source "${DIR}/../../test/common.bash"

${VIRGIL_LOC}/test/configure

TEST_TARGETS="jvm"
aeneas test
