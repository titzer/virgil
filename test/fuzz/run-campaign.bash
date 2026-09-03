#!/usr/bin/env bash
# run-campaign.bash — Top-level fuzzing campaign orchestrator.
#
# Runs fuzz-exec and fuzz-parser in parallel under a single CTRL+C handler.
#
# Usage:
#   ./run-campaign.bash [--seed SEED] [--duration SECS] [--exec-only] [--parser-only]
#
# Environment:
#   FUZZ_V3C        compiler under test (built from current source)
#   FUZZ_TARGETS    targets for fuzz-exec (default: auto-detect)
#   VIRGIL_FUZZ_SEED  default seed

set -uo pipefail

FUZZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SEED="${VIRGIL_FUZZ_SEED:-$(date +%s)}"
DURATION=0
RUN_EXEC=true
RUN_PARSER=true
EXTRA=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --seed)        SEED="$2"; shift 2 ;;
        --duration)    DURATION="$2"; shift 2 ;;
        --exec-only)   RUN_PARSER=false; shift ;;
        --parser-only) RUN_EXEC=false; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done
[[ $DURATION -gt 0 ]] && EXTRA+=(--duration "$DURATION")

echo "=== Virgil Fuzzing Campaign ==="
echo "Compiler   : ${FUZZ_V3C:-${AENEAS_TEST:-bin/v3c}}"
echo "Seed       : $SEED"
echo "Duration   : $([[ $DURATION -gt 0 ]] && echo "${DURATION}s" || echo "until CTRL+C")"
echo "Exec fuzz  : $RUN_EXEC"
echo "Parser fuzz: $RUN_PARSER"
echo "Bugs dir   : ${FUZZ_BUGS_DIR:-$FUZZ_DIR/bugs}/"
echo ""

pids=()
if $RUN_EXEC; then
    bash "$FUZZ_DIR/fuzz-exec.bash" --seed "$SEED" "${EXTRA[@]}" &
    pids+=($!)
fi
if $RUN_PARSER; then
    bash "$FUZZ_DIR/fuzz-parser.bash" --seed "$((SEED + 1000000))" "${EXTRA[@]}" &
    pids+=($!)
fi

# On INT/TERM: forward the signal to each worker, then wait for them to finish
# their current batch and print their summaries (via their own EXIT traps).
cleanup() {
    echo ""
    echo "[campaign] Stopping workers (finishing current batch)..."
    for pid in "${pids[@]}"; do kill -INT "$pid" 2>/dev/null || true; done
    wait "${pids[@]}" 2>/dev/null || true
    echo "[campaign] Done. Check ${FUZZ_BUGS_DIR:-$FUZZ_DIR/bugs}/ for findings."
}
trap 'cleanup; exit 130' INT TERM
trap 'wait 2>/dev/null || true' EXIT

wait "${pids[@]}" 2>/dev/null || true
echo "[campaign] Done. Check ${FUZZ_BUGS_DIR:-$FUZZ_DIR/bugs}/ for findings."
