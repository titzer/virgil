#!/usr/bin/env bash
# Builds and tests the arm64-linux target on a native arm64 linux host, such as
# GitHub's ubuntu-24.04-arm runners. The stable compiler has no arm64-linux
# binary and does not know the target, so the compiler under test is hosted on
# the JVM (TEST_HOST=jar): stable compiles the bootstrap compiler to a JAR, the
# suites run on that, and the bootstrap check recompiles it to a JAR as well.

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/test"

if [ "$(uname -sm)" != "Linux aarch64" ]; then
    echo "This test requires an arm64 linux host."
    exit 1
fi

if [ "$(type -t java)" = "" ]; then
    echo "Install java"
    sudo apt -y install default-jre-headless
fi

if [ "$(type -t nasm)" = "" ]; then
    echo "Install nasm"
    sudo apt -y install nasm
fi

"${TEST_DIR}"/configure

V3C_OPTS="$@" PROGRESS_ARGS=c TEST_HOST=jar TEST_TARGETS="v3i arm64-linux" "${TEST_DIR}"/all.bash || exit $?

# The arm64 assembler tests need a native arm64 "as" and "objdump", so they are
# not among the default suites. Run them on the bootstrap compiler that all.bash
# just built and tested.
BOOTSTRAP=/tmp/$USER/virgil-test${CI_DIR:+/$CI_DIR}/aeneas/bootstrap/jar/Aeneas
echo --------------------------------------------------------------------------------
echo "($BOOTSTRAP) asm/arm64"
(cd "${TEST_DIR}/asm/arm64" && AENEAS_TEST=$BOOTSTRAP PROGRESS_ARGS=c ./test.bash) || exit $?
