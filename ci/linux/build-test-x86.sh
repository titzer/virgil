#!/usr/bin/env bash

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

if [ "$(type -t nasm)" = "" ]; then
    echo "Install nasm"
    sudo apt -y install nasm
fi

"${TEST_DIR}"/configure

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_TARGETS="v3i x86-linux" "${TEST_DIR}"/all.bash
