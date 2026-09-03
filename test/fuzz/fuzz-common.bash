#!/usr/bin/env bash
# fuzz-common.bash — shared setup and helpers for the fuzzing scripts.
#
# Source this file; it defines paths, the compiler under test, the set of
# test inputs, and helpers for running the compiler's -test mode over a
# batch of files and parsing its ##+/##-ok/##-fail progress output.

FUZZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIRGIL_ROOT="$(cd "$FUZZ_DIR/../.." && pwd)"
BUGS_DIR="${FUZZ_BUGS_DIR:-$FUZZ_DIR/bugs}"
SMITH_DIR="$FUZZ_DIR/virgil-smith"
SMITH="$SMITH_DIR/virgil-smith.rkt"
GEN_BATCH="$SMITH_DIR/gen-batch.rkt"
TEST_BIN="$VIRGIL_ROOT/test/bin"
TEST_CONFIG="$VIRGIL_ROOT/test/config"

# The compiler under test. This must be built from current source (it needs
# -test.update); bin/v3c may point at a stale stable binary.
#   FUZZ_V3C > AENEAS_TEST > bin/v3c
V3C="${FUZZ_V3C:-${AENEAS_TEST:-$VIRGIL_ROOT/bin/v3c}}"

# Inputs passed to main(a: int) of every generated program. Extremes are
# included to exercise overflow, sign, and constant-folding corner cases.
FUZZ_INPUTS="${FUZZ_INPUTS:-0 1 -1 2 3 7 42 100 1000 -1000 65536 2147483647 -2147483648}"

# Per-invocation timeout (seconds) for the compiler or a test runner.
FUZZ_TIMEOUT="${FUZZ_TIMEOUT:-60}"

mkdir -p "$BUGS_DIR"

info()  { echo "[$FUZZ_TAG] $*"; }
warn()  { echo "[$FUZZ_TAG WARN] $*" >&2; }
bug()   { echo "[$FUZZ_TAG BUG!] $*" >&2; }

# Check that the compiler under test exists and supports -test.update.
check_compiler() {
    if [[ ! -x "$V3C" ]]; then
        echo "ERROR: compiler not found or not executable: $V3C" >&2
        echo "Set FUZZ_V3C to a compiler built from current source." >&2
        exit 1
    fi
    local tmp
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/fuzz-check-XXXX")
    printf '//@execute 0=1\ndef main(a: int) -> int { return a; }\n' > "$tmp/chk.v3"
    if ! "$V3C" -test -test.update "$tmp/chk.v3" >/dev/null 2>&1 || \
       ! grep -q '^//@execute 0=0$' "$tmp/chk.v3"; then
        echo "ERROR: $V3C does not support -test.update (is it built from current source?)" >&2
        rm -rf "$tmp"
        exit 1
    fi
    rm -rf "$tmp"
}

# Run a command with a timeout (macOS has no coreutils `timeout`).
# Exit code 142 (SIGALRM) indicates a timeout.
with_timeout() {
    local secs="$1"; shift
    perl -e 'alarm shift @ARGV; exec @ARGV or exit 127' "$secs" "$@"
}

# Build a placeholder //@execute header listing all inputs; the interpreter
# fills in the real expectations with -test.update.
make_execute_header() {
    local hdr="//@execute " first=true
    for i in $FUZZ_INPUTS; do
        if $first; then hdr="$hdr$i=0"; first=false; else hdr="$hdr; $i=0"; fi
    done
    echo "$hdr"
}

# Prepend the placeholder header to a generated program (in place).
add_execute_header() {
    local f="$1" tmp="$1.hdr"
    { make_execute_header; cat "$f"; } > "$tmp" && mv "$tmp" "$f"
}

# Parse ##+/##-ok/##-fail progress output. Prints one line per test:
#     <name>\t<status>\t<message>
# where status is ok, fail, or crash (a ##+ line with no matching result,
# meaning the process died or timed out while running that test).
# Names have any trailing ".v3" removed so that runners which print bare
# names (the wasm tester) match those that print file names.
parse_results() {
    awk '
        function flush(st, msg) { if (cur != "") printf "%s\t%s\t%s\n", cur, st, msg; cur = "" }
        /^##\+/ { flush("crash", "no result (process died or timed out)"); cur = substr($0, 4); sub(/\.v3$/, "", cur); next }
        /^##-ok/ { flush("ok", ""); next }
        /^##-fail: / { flush("fail", substr($0, 10)); next }
        END { flush("crash", "no result (process died or timed out)") }
    ' "$1"
}

# Run "$V3C -test FLAGS files..." over a batch, tolerating crashes: when the
# process dies part way through, the file being tested is recorded as a crash
# and the remaining files are rerun. Results (parse_results format) are
# written to $2; files are given on the remaining arguments.
# Usage: run_v3c_test_batch "FLAGS" RESULTS_FILE file...
run_v3c_test_batch() {
    local flags="$1" results="$2"; shift 2
    local files=("$@")
    local raw="$results.raw"
    : > "$results"
    while [[ ${#files[@]} -gt 0 ]]; do
        # shellcheck disable=SC2086
        with_timeout "$FUZZ_TIMEOUT" "$V3C" -test $flags "${files[@]}" > "$raw" 2>&1
        local rc=$?
        parse_results "$raw" >> "$results"
        if [[ $rc -le 1 ]]; then break; fi   # 0 = all pass, 1 = some failed
        # The process died (signal, timeout, or internal error exit code).
        local crashed
        crashed=$(awk -F'\t' '$2 == "crash" { print $1 }' "$results" | tail -1)
        local rest=() seen=false
        for f in "${files[@]}"; do
            if $seen; then rest+=("$f"); fi
            if [[ "${f%.v3}" == "$crashed" ]]; then seen=true; fi
        done
        if [[ -z "$crashed" ]]; then
            # Died before starting any test; record against the first file.
            printf '%s\tcrash\texit code %d before running any test\n' "${files[0]%.v3}" "$rc" >> "$results"
            rest=("${files[@]:1}")
        fi
        files=("${rest[@]}")
    done
}

# Find the test runner script/binary for a compiled target.
# Prefers test/config/test-<target>* (set up by test/configure), then
# test/bin/test-<target> (the raw native tester, e.g. for Rosetta hosts).
find_runner() {
    local target="$1" r
    for r in "$TEST_CONFIG"/test-"$target"*; do
        [[ -x "$r" ]] && { echo "$r"; return 0; }
    done
    r="$TEST_BIN/test-$target"
    [[ -x "$r" ]] && { echo "$r"; return 0; }
    return 1
}

# Extra compiler flags needed for a given test target.
target_compile_flags() {
    case "$1" in
        jvm) echo "-jvm.script=false" ;;
        *)   echo "" ;;
    esac
}

# Compile a batch of tests for a target and run them with the target's runner.
# Usage: run_target_batch TARGET "OPTS" OUTDIR RESULTS_FILE file...
# Compile failures and run failures are both reported in RESULTS_FILE.
run_target_batch() {
    local target="$1" opts="$2" outdir="$3" results="$4"; shift 4
    local files=("$@")
    local runner
    runner=$(find_runner "$target") || { warn "no runner for $target"; return 1; }
    rm -rf "$outdir"; mkdir -p "$outdir"
    local craw="$results.compile.raw" rraw="$results.run.raw"
    # shellcheck disable=SC2086
    with_timeout "$FUZZ_TIMEOUT" "$V3C" -multiple -set-exec=false -target="$target-test" \
        $(target_compile_flags "$target") $opts -output="$outdir" "${files[@]}" > "$craw" 2>&1
    local rc=$?
    parse_results "$craw" | awk -F'\t' -v OFS='\t' '$2 != "ok" { $3 = "compile: " $3; print }' > "$results"
    if [[ $rc -gt 1 ]]; then
        # Compiler died; mark every file without a result as a compile crash.
        for f in "${files[@]}"; do
            local n="${f%.v3}"
            grep -q "^${n}"$'\t' "$results" || printf '%s\tcrash\tcompile: compiler exit code %d\n' "$n" "$rc" >> "$results"
        done
    fi
    # Run only the files that compiled.
    local torun=()
    for f in "${files[@]}"; do
        grep -q "^${f%.v3}"$'\t' "$results" || torun+=("$f")
    done
    if [[ ${#torun[@]} -gt 0 ]]; then
        with_timeout "$((FUZZ_TIMEOUT * 5))" "$runner" "$outdir" "${torun[@]}" > "$rraw" 2>&1
        parse_results "$rraw" | awk -F'\t' '$2 != "ok"' >> "$results"
    fi
}

# Save a bug: copies the .v3 to BUGS_DIR under a descriptive name and writes
# a .log alongside describing which configurations failed and how.
# Usage: save_bug KIND SEED FILE LOGTEXT
save_bug() {
    local kind="$1" seed="$2" file="$3" log="$4"
    local base="$BUGS_DIR/${kind}-seed${seed}"
    cp "$file" "$base.v3"
    {
        echo "compiler: $V3C"
        echo "date:     $(date +%Y-%m-%dT%H:%M:%S)"
        echo "seed:     $seed"
        echo "$log"
    } > "$base.log"
    echo "$base.v3"
}
