#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

"${TEST_DIR}"/configure

V3C_OPTS=-O3 PROGRESS_ARGS=c TEST_TARGETS="wasm-js" "${TEST_DIR}"/all.bash
