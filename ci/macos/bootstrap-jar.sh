#!/usr/bin/env bash
# Compiles the compiler for the JVM in two steps, stable -> bootstrap -> current,
# for hosts that cannot run any of the stable compiler's native binaries.
#
# Usage: bootstrap-jar.sh <output dir>
# The compiler is then <output dir>/current/jar/Aeneas.

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="$(cd "${DIR}/../.." && pwd)"
OUT=$1

JVM_ARGS="-client -Xms900m -Xmx900m -XX:+UseSerialGC"

cd "$VIRGIL_LOC"
SRCS="aeneas/src/*/*.v3 $(cat aeneas/DEPS)"
HOST=$VIRGIL_LOC/bin/stable/jar/Aeneas

for stage in bootstrap current; do
    echo "Compiling ($HOST -> $OUT/$stage/jar/Aeneas)..."
    mkdir -p $OUT/$stage/jar
    V3C=$HOST bin/v3c-jar -fp $V3C_OPTS -jvm.args="$JVM_ARGS" -output=$OUT/$stage/jar $SRCS || exit $?
    HOST=$OUT/$stage/jar/Aeneas
done
