#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

echo "Install nasm"
sudo apt -y install nasm

"${TEST_DIR}"/configure

# XXX(kunals): Temporarily release aeneas to avoid infinte loop in CI
${VIRGIL_LOC}/bin/dev/aeneas release

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_TARGETS="v3i x86-linux" "${TEST_DIR}"/all.bash
