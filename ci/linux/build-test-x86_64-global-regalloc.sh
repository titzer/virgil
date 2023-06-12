#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

echo "Install nasm"
sudo apt -y install nasm

"${TEST_DIR}"/configure

V3C_OPTS=-global-regalloc PROGRESS_ARGS=c TEST_HOST=x86-64-linux TEST_TARGETS="v3i x86-64-linux" "${TEST_DIR}"/all.bash
