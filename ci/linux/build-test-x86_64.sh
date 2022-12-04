#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

"${TEST_DIR}"/configure

PROGRESS_ARGS=l TEST_TARGETS="int x86-64-linux" "${TEST_DIR}"/all.bash
