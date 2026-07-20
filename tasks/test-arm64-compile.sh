#!/usr/bin/env bash
# Compile tests for arm64-linux-test and report pass/fail counts.
# Usage:
#   tasks/test-arm64-compile.sh                    # all core tests
#   tasks/test-arm64-compile.sh test/core/add*.v3  # specific tests
#
# Writes filtered lists to /tmp/arm64-test/:
#   compiled.txt  — test files that compiled successfully
#   failed.txt    — test files that failed to compile (with reasons)
#   raw.txt       — full compiler output
# Prints a summary to stdout.

VIRGIL=$(cd "$(dirname "$0")/.." && pwd)
cd "$VIRGIL"

OUTDIR=/tmp/arm64-test
mkdir -p "$OUTDIR"

TMPOUT=$(mktemp -d)
if [ $# -gt 0 ]; then
    bin/v3c -multiple -target=arm64-linux-test -output="$TMPOUT" "$@" > "$OUTDIR/raw.txt" 2>&1
else
    bin/v3c -multiple -target=arm64-linux-test -output="$TMPOUT" test/core/*.v3 > "$OUTDIR/raw.txt" 2>&1
fi

# Extract compiled and failed test lists
grep -B1 '##-ok' "$OUTDIR/raw.txt" | grep '##+' | sed 's/##+//' > "$OUTDIR/compiled.txt"
grep -B1 '##-fail' "$OUTDIR/raw.txt" | grep '##+' | sed 's/##+//' > "$OUTDIR/failed-names.txt"
grep '##-fail' "$OUTDIR/raw.txt" > "$OUTDIR/failed.txt"

OK=$(wc -l < "$OUTDIR/compiled.txt" | tr -d ' ')
FAIL=$(wc -l < "$OUTDIR/failed-names.txt" | tr -d ' ')
TOTAL=$((OK + FAIL))

echo "=== arm64-linux-test compilation ==="
echo "Passed: $OK / $TOTAL"
echo "Failed: $FAIL / $TOTAL"

if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "Failure categories:"
    grep -oE 'unexpected opcode [A-Za-z]+|Alloc without|expected GPR|invalid opcode [a-z0-9= ]+' "$OUTDIR/failed.txt" | sort | uniq -c | sort -rn
fi

echo ""
echo "Lists written to $OUTDIR/{compiled,failed,raw}.txt"

rm -rf "$TMPOUT"
