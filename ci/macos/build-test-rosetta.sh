#!/usr/bin/env bash
# Tests the x86-64-darwin target on an arm64 host using Rosetta 2: first the
# compiler itself, by having it compile itself, and then a subset of the test
# suites, since every new program has to be translated before it runs.

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="$(cd "${DIR}/../.." && pwd)"
TEST_DIR="${VIRGIL_LOC}/test"
OUT=/tmp/$USER/virgil-rosetta

SUITES=${SUITES:="unit smoke darwin system rt stacktrace lib large"}

if [ "$(uname -sm)" != "Darwin arm64" ]; then
    echo "This test requires an arm64 darwin host."
    exit 1
fi

if ! arch -x86_64 /usr/bin/true 2> /dev/null; then
    echo "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license \
	|| sudo -n softwareupdate --install-rosetta --agree-to-license \
	|| exit $?
fi

# Link the x86-64-darwin test runners.
USE_ROSETTA2=1 "${TEST_DIR}"/configure

export V3C_OPTS="$@"
export PROGRESS_ARGS=c
export UNITTEST=1
export TEST_TARGETS="v3i x86-64-darwin"

# Build the compiler for the JVM first, because the stable compiler's native
# binary, and the binaries that it generates, might not run under Rosetta 2.
rm -rf $OUT
"${DIR}"/bootstrap-jar.sh $OUT || exit $?

cd "$VIRGIL_LOC"
SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
HOST=$OUT/current/jar/Aeneas

for stage in native1 native2; do
    echo "Compiling ($HOST -> $OUT/$stage/Aeneas)..."
    mkdir -p $OUT/$stage
    V3C=$HOST bin/v3c-x86-64-darwin -fp -heap-size=600m $V3C_OPTS -output=$OUT/$stage $SRCS || exit $?
    HOST=$OUT/$stage/Aeneas
done

# The compiler running under Rosetta 2 must reproduce itself exactly.
if ! cmp $OUT/native1/Aeneas $OUT/native2/Aeneas; then
    echo "x86-64-darwin compiler did not reproduce itself."
    exit 1
fi
echo "  bootstrap on x86-64-darwin ok"

export AENEAS_TEST=$OUT/native2/Aeneas
export V3C_OPTS="$V3C_OPTS -heap-size=600m"

for suite in $SUITES; do
    echo --------------------------------------------------------------------------------
    echo "($AENEAS_TEST) $suite"
    (cd "${TEST_DIR}/$suite" && ./test.bash) || exit $?
done
