#!/usr/bin/env bash
# Compare enum scalability across Strategy A and Strategy B compilers.
#
# Usage: ./run-bench.bash [num_cases]
#
# Env vars:
#   AENEAS_A  - path to Strategy A compiler (default: built from open_enums3a)
#   AENEAS_B  - path to Strategy B compiler (default: built from open_enums3b)
#   TARGETS   - space-separated targets (default: "x86-64-linux")
#   RUNS      - runs per timing measurement (default: 3)
#   N         - number of enum cases (default: 1000, overridden by $1)

set -euo pipefail

DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VIRGIL_LOC=${VIRGIL_LOC:=$(cd "$DIR/../.." && pwd)}

N=${1:-${N:-1000}}
TARGETS=${TARGETS:-"x86-64-linux"}
RUNS=${RUNS:-3}
TMP=/tmp/$USER/virgil-bench/enum-scale
mkdir -p "$TMP"

# ---------- generate source ----------
SRC="$TMP/BigEnum_${N}.v3"
if [ ! -f "$SRC" ]; then
    echo "Generating enum with $N cases, 4 params each..."
    bash "$DIR/generate.bash" "$N" > "$SRC"
    wc -l "$SRC"
fi

# ---------- resolve compilers ----------
AENEAS_A=${AENEAS_A:-$VIRGIL_LOC/bin/current/x86-64-linux/Aeneas}
AENEAS_B=${AENEAS_B:-$VIRGIL_LOC/bin/current/x86-64-linux/Aeneas}
if [ ! -x "$AENEAS_A" ]; then AENEAS_A=$VIRGIL_LOC/bin/current/x86-linux/Aeneas; fi
if [ ! -x "$AENEAS_B" ]; then AENEAS_B=$VIRGIL_LOC/bin/current/x86-linux/Aeneas; fi

# ---------- helper: compile + measure ----------
compile_and_measure() {
    local label=$1 aeneas=$2 target=$3 tag=$4
    local outdir="$TMP/${tag}_${target}"
    local progname="big_${tag}"
    mkdir -p "$outdir"

    local RT=$VIRGIL_LOC/rt
    local rt_files compile_args runcmd binary

    local can_run=true
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
    local best_compile=""
    for run in $(seq 1 $RUNS); do
        rm -f "$binary"
        local elapsed
        elapsed=$( { /usr/bin/time -f "%e %M" \
            "$aeneas" $compile_args -rt.files="$rt_files" \
            -output="$outdir" -program-name="$progname" "$SRC" ; } 2>&1 | tail -1 )
        local secs=$(echo "$elapsed" | awk '{print $1}')
        local mem=$(echo "$elapsed" | awk '{print $2}')
        if [ -z "$best_compile" ] || [ $(echo "$secs < $best_compile" | bc) = 1 ]; then
            best_compile=$secs
            best_mem=$mem
        fi
    done

    # --- binary size ---
    local binsize
    if [ "$target" = "jar" ]; then
        binsize=$(stat -c%s "$binary" 2>/dev/null || stat -f%z "$binary")
    else
        binsize=$(stat -c%s "$binary" 2>/dev/null || stat -f%z "$binary")
    fi

    # --- runtime: execute test 3 (steady-state iteration), measure RSS ---
    local best_run="" run_rss=""
    if [ "$can_run" = "true" ]; then
        for run in $(seq 1 $RUNS); do
            local elapsed
            elapsed=$( { /usr/bin/time -f "%e %M" $runcmd 3 ; } 2>&1 | tail -1 )
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

    printf "  %-14s  compile: %6ss  %6s KB   binary: %8s B   run: %6ss  %6s KB\n" \
        "$label" "$best_compile" "$best_mem" "$binsize" "$best_run" "$run_rss"
}

# ---------- wasm-gc runner if needed ----------
if [[ "$TARGETS" == *"wasm-gc"* ]]; then
    RUNNER=$TMP/run-wgc.mjs
    if [ ! -f "$RUNNER" ]; then
        cat > "$RUNNER" << 'JSEOF'
import { readFileSync } from 'node:fs';
import { WASI } from 'wasi';
import { argv, env } from 'node:process';
const wasi = new WASI({ returnOnExit: false, version: 'preview1', args: argv.slice(2), env, preopens: { '.': '.' } });
const importObject = { wasi_snapshot_preview1: wasi.wasiImport };
const instance = new WebAssembly.Instance(new WebAssembly.Module(readFileSync(argv[2])), importObject);
wasi.initialize(instance);
instance.exports.entry();
JSEOF
    fi
fi

# ---------- main ----------
echo "========================================"
echo "Enum Scalability Benchmark"
echo "  Cases: $N   Params: 4   Methods: 3"
echo "  Runs: $RUNS (best of)"
echo "========================================"

for target in $TARGETS; do
    echo ""
    echo "--- $target ---"
    echo "  Strategy        compile-time  compile-RSS   binary-size      run-time    run-RSS"
    compile_and_measure "Strategy-A" "$AENEAS_A" "$target" "stratA"
    compile_and_measure "Strategy-B" "$AENEAS_B" "$target" "stratB"

    # --- diff summary ---
    echo ""
    sA="$TMP/stratA_${target}/big_stratA"
    sB="$TMP/stratB_${target}/big_stratB"
    if [ "$target" = "jar" ]; then sA="${sA}.jar"; sB="${sB}.jar"; fi
    if [ -f "$sA" ] && [ -f "$sB" ]; then
        szA=$(stat -c%s "$sA" 2>/dev/null || stat -f%z "$sA")
        szB=$(stat -c%s "$sB" 2>/dev/null || stat -f%z "$sB")
        if [ "$szA" -gt 0 ]; then
            pct=$(echo "scale=1; ($szB - $szA) * 100 / $szA" | bc)
            echo "  Binary delta: B is ${pct}% vs A  ($szA -> $szB bytes)"
        fi
    fi
done

echo ""
echo "Done."
