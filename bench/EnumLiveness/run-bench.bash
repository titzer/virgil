#!/usr/bin/env bash
# Measure effect of per-case liveness analysis on enum compilation.
# Compiles the same N-case enum with varying numbers of live cases (K).
#
# Usage: ./run-bench.bash [N]
#
# Env vars:
#   AENEAS    - compiler to test (default: bin/current/x86-linux/Aeneas)
#   TARGETS   - space-separated targets (default: "x86-64-linux")
#   RUNS      - runs per timing measurement (default: 3)
#   N         - total enum cases (default: 1000, overridden by $1)
#   K_VALUES  - space-separated K values (default: "10 50 100 500 N")

set -euo pipefail

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VIRGIL_LOC=${VIRGIL_LOC:=$(cd "$DIR/../.." && pwd)}

N=${1:-${N:-1000}}
TARGETS=${TARGETS:-"x86-64-linux"}
RUNS=${RUNS:-3}
K_VALUES=${K_VALUES:-"10 50 100 500 $N"}
TMP=/tmp/$USER/virgil-bench/enum-liveness
mkdir -p "$TMP"

# ---------- resolve compiler ----------
AENEAS=${AENEAS:-$VIRGIL_LOC/bin/current/x86-64-linux/Aeneas}
if [ ! -x "$AENEAS" ]; then AENEAS=$VIRGIL_LOC/bin/current/x86-linux/Aeneas; fi

# ---------- generate sources ----------
for K in $K_VALUES; do
    SRC="$TMP/BigEnum_${N}_${K}.v3"
    if [ ! -f "$SRC" ]; then
        bash "$DIR/generate.bash" "$N" "$K" > "$SRC"
    fi
done

# ---------- helper: compile + measure ----------
compile_and_measure() {
    local label=$1 src=$2 target=$3 tag=$4
    local outdir="$TMP/${tag}_${target}"
    local progname="big_${tag}"
    mkdir -p "$outdir"

    local RT=$VIRGIL_LOC/rt
    local rt_files compile_args binary

    local can_run=true runcmd=""
    if [ "$target" = "jar" ]; then
        binary="$outdir/$progname.jar"
        rt_files=""
        compile_args="-target=jar"
        runcmd="java -jar $binary"
    elif [ "$target" = "wasm-gc" ]; then
        binary="$outdir/$progname.wasm"
        rt_files="$(echo $RT/wasm-gc-wasi1/*.v3 $RT/wasm-wasi1-common/*.v3)"
        compile_args="-target=wasm-gc"
        can_run=false
    elif [ "$target" = "wasm" ]; then
        binary="$outdir/$progname.wasm"
        rt_files="$(echo $RT/wasm-wasi1/*.v3 $RT/wasm-wasi1-common/*.v3 $RT/native/NativeFileStream.v3)"
        compile_args="-target=wasm"
        can_run=false
    else
        binary="$outdir/$progname"
        rt_files="$(echo $RT/$target/*.v3 $RT/native/*.v3 $RT/gc/*.v3)"
        compile_args="-heap-size=200m -target=$target"
        runcmd="$binary"
    fi

    # --- compile timing (best of RUNS) ---
    local best_compile="" best_mem=""
    for run in $(seq 1 $RUNS); do
        rm -f "$binary"
        local elapsed
        elapsed=$( { /usr/bin/time -f "%e %M" \
            "$AENEAS" $compile_args -rt.files="$rt_files" \
            -output="$outdir" -program-name="$progname" "$src" ; } 2>&1 | tail -1 )
        local secs=$(echo "$elapsed" | awk '{print $1}')
        local mem=$(echo "$elapsed" | awk '{print $2}')
        if [ -z "$best_compile" ] || [ $(echo "$secs < $best_compile" | bc) = 1 ]; then
            best_compile=$secs
            best_mem=$mem
        fi
    done

    local binsize
    binsize=$(stat -c%s "$binary" 2>/dev/null || stat -f%z "$binary")

    # --- runtime (best of RUNS), test 0 = sum with iterations ---
    local best_run="" run_rss=""
    if [ "$can_run" = "true" ]; then
        for run in $(seq 1 $RUNS); do
            local elapsed
            elapsed=$( { /usr/bin/time -f "%e %M" $runcmd 0 ; } 2>&1 | tail -1 )
            local secs=$(echo "$elapsed" | awk '{print $1}')
            local mem=$(echo "$elapsed" | awk '{print $2}')
            if [ -z "$best_run" ] || [ $(echo "$secs < $best_run" | bc) = 1 ]; then
                best_run=$secs
                run_rss=$mem
            fi
        done
    else
        best_run="n/a"
        run_rss="n/a"
    fi

    printf "  K=%-5s  compile: %6ss %6sKB   bin: %8sB   run: %6ss %6sKB\n" \
        "$label" "$best_compile" "$best_mem" "$binsize" "$best_run" "$run_rss"
}

# ---------- main ----------
echo "========================================"
echo "Enum Liveness Benchmark"
echo "  Total cases: $N   K values: $K_VALUES"
echo "  Runs: $RUNS (best of)"
echo "  Compiler: $AENEAS"
echo "========================================"

for target in $TARGETS; do
    echo ""
    echo "--- $target ---"
    echo "  K         compile-time  comp-RSS   binary-size      run-time  run-RSS"
    for K in $K_VALUES; do
        compile_and_measure "$K" "$TMP/BigEnum_${N}_${K}.v3" "$target" "k${K}"
    done
done

echo ""
echo "Done."
