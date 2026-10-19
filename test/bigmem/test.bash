#!/usr/bin/env bash

. ../common.bash bigmem

# Wasm tests that access linear memory above 2GB, which needs the largest heap.
V3C_OPTS="$V3C_OPTS -heap-size=2147483647"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

# The JVM-hosted spec runner cannot allocate such a large memory.
FILTERED=$OUT/config
mkdir -p $FILTERED
for f in $CONFIG/*; do
	case ${f##*/} in
		test-wasm-spec@wizeng) ;;
		*) ln -sf $f $FILTERED/ ;;
	esac
done
CONFIG=$FILTERED

TARGETS=""
for target in $TEST_TARGETS; do
	if [ "$target" = wasm ]; then TARGETS="$TARGETS $target"; fi
done
TEST_TARGETS="$TARGETS"
execute_tests
