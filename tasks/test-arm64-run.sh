#!/usr/bin/env bash
# Compile and execute tests for arm64-linux via Docker.
# Filters to compilable tests, then runs them.
#
# Usage:
#   tasks/test-arm64-run.sh                      # all core tests
#   tasks/test-arm64-run.sh test/core/add*.v3    # specific tests
#
# Reads from /tmp/arm64-test/compiled.txt (produced by test-arm64-compile.sh).
# If that file doesn't exist or args are given, compiles first.
#
# Writes results to /tmp/arm64-test/:
#   run-passed.txt  — tests that passed execution
#   run-failed.txt  — tests that failed execution (with reasons)
#
# Requires: Docker with linux/arm64 platform support.

VIRGIL=$(cd "$(dirname "$0")/.." && pwd)
cd "$VIRGIL"

OUTDIR=/tmp/arm64-test
mkdir -p "$OUTDIR"

# Determine which test suite directory we're working with
SUITE_DIR="test/core"

if [ $# -gt 0 ]; then
    # Specific tests given — compile them first
    bash "$VIRGIL/tasks/test-arm64-compile.sh" "$@"
    # Figure out the suite dir from the first argument
    SUITE_DIR=$(dirname "$1")
else
    # Use cached compiled.txt if fresh, otherwise compile
    if [ ! -f "$OUTDIR/compiled.txt" ] || [ -z "$(cat "$OUTDIR/compiled.txt")" ]; then
        bash "$VIRGIL/tasks/test-arm64-compile.sh"
    fi
fi

COMPILED=$(cat "$OUTDIR/compiled.txt")
COUNT=$(wc -l < "$OUTDIR/compiled.txt" | tr -d ' ')

if [ "$COUNT" -eq 0 ]; then
    echo "No tests compiled successfully."
    exit 1
fi

# Convert to basenames for test.bash
BASENAMES=()
for t in $COMPILED; do
    BASENAMES+=("$(basename "$t")")
done

echo ""
echo "=== Running $COUNT tests via Docker ==="

cd "$VIRGIL/$SUITE_DIR"
TEST_TARGETS="arm64-linux" bash test.bash "${BASENAMES[@]}" 2>&1 > /dev/null

# Find and parse run output
RUN_FILE=$(find /tmp/titzer/virgil-test -name 'run.out' -path '*/arm64-linux/*' 2>/dev/null | head -1)
if [ -z "$RUN_FILE" ]; then
    echo "Could not find run.out — did Docker run?"
    exit 1
fi

# Write filtered lists
grep -B1 '##-ok' "$RUN_FILE" | grep '##+' | sed 's/##+//' > "$OUTDIR/run-passed.txt"
grep -B1 '##-fail' "$RUN_FILE" | grep '##+' | sed 's/##+//' > "$OUTDIR/run-failed-names.txt"
grep '##-fail' "$RUN_FILE" > "$OUTDIR/run-failed.txt"

RUN_OK=$(wc -l < "$OUTDIR/run-passed.txt" | tr -d ' ')
RUN_FAIL=$(wc -l < "$OUTDIR/run-failed-names.txt" | tr -d ' ')

echo ""
echo "=== Results ==="
echo "Compile: $COUNT / $(wc -l < "$OUTDIR/compiled.txt" | tr -d ' ')"
echo "Execute: $RUN_OK / $COUNT ($RUN_FAIL failed)"

if [ "$RUN_FAIL" -gt 0 ]; then
    echo ""
    echo "Runtime failure categories:"
    grep -oE 'signal [0-9]+|wrong result.*' "$OUTDIR/run-failed.txt" | sort | uniq -c | sort -rn
fi

echo ""
echo "Lists written to $OUTDIR/{run-passed,run-failed}.txt"
