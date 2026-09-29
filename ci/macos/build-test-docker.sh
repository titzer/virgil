#!/usr/bin/env bash
# Tests the x86-64-linux target on a darwin host, running the programs in docker,
# which on arm64 emulates x86-64. Runs a subset of the test suites, since
# starting a container for a program takes far longer than the program.

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="$(cd "${DIR}/../.." && pwd)"
TEST_DIR="${VIRGIL_LOC}/test"
OUT=/tmp/$USER/virgil-docker

SUITES=${SUITES:="unit smoke linux system rt stacktrace lib link vmaddr gc"}

if ! docker info > /dev/null 2>&1; then
    echo "This test requires docker, and it is not running."
    exit 1
fi

"${TEST_DIR}"/configure

export V3C_OPTS="$@"
export PROGRESS_ARGS=c
export UNITTEST=1
export TEST_TARGETS="v3i x86-64-linux"

rm -rf $OUT
"${DIR}"/bootstrap-jar.sh $OUT || exit $?

export AENEAS_TEST=$OUT/current/jar/Aeneas

for suite in $SUITES; do
    echo --------------------------------------------------------------------------------
    echo "($AENEAS_TEST) $suite"
    (cd "${TEST_DIR}/$suite" && ./test.bash) || exit $?
done
