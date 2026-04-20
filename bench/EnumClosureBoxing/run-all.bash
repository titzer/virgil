#!/usr/bin/env bash
# Run all EnumClosureBoxing test cases and report per-case timing.
# Usage: ./run-all.bash <target> [iterations]
#   target: x86-64-linux, jar, wasm-gc, etc.
#   iterations: default 100000000
# Env: V3C_OPTS  - extra compiler options (e.g., "-O2 -wfts=true")
#      RUNS      - number of runs per test (default 5)
#      AENEAS    - compiler binary to use

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
VIRGIL_LOC=${VIRGIL_LOC:=$(cd "$DIR/../.." && pwd)}

if [ $# = 0 ]; then
    echo "Usage: run-all.bash <target> [iterations]"
    exit 1
fi

target=$1
iters=${2:-100000000}
RUNS=${RUNS:-5}

TMP=/tmp/$USER/virgil-bench/ecb
opts_tag=$(echo "$V3C_OPTS" | tr ' =-' '_ep' | tr -cd 'A-Za-z0-9_')
PROGNAME="ecb${opts_tag:+-$opts_tag}"
mkdir -p $TMP

AENEAS=${AENEAS:-$VIRGIL_LOC/bin/current/x86-64-linux/Aeneas}
if [ ! -x "$AENEAS" ]; then
    AENEAS=$VIRGIL_LOC/bin/current/x86-linux/Aeneas
fi

CORE=$DIR/EnumClosureBoxingCore.v3

labels=(
    "direct call (no closure)"
    "monomorphic closure (JIT inlines)"
    "bimorphic closure (2 cases)"
    "megamorphic closure (4 cases)"
    "closure escape (adapter)"
    "closure array iteration"
)

# Determine run command based on target
RT_FILES=""
if [ "$target" = "jar" ]; then
    PROG=$TMP/$PROGNAME.jar
    RUNCMD="java -jar $PROG"
    COMPILE_ARGS="-target=jar"
    SRCS="$CORE $DIR/EnumClosureBoxing.v3"
elif [ "$target" = "wasm-gc" ]; then
    PROGNAME="${PROGNAME}-wgc"
    PROG=$TMP/$PROGNAME.wasm
    RT=$VIRGIL_LOC/rt
    RT_FILES=$(echo $RT/wasm-gc-wasi1/*.v3 $RT/wasm-wasi1-common/wasi_snapshot_preview1.v3)
    COMPILE_ARGS="-target=wasm-gc"
    SRCS="$CORE $DIR/EnumClosureBoxing.v3"
    # Create wasm-gc runner script if needed
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
    NODE=$(which node)
    RUNCMD="$NODE --experimental-wasi-unstable-preview1 $RUNNER $PROG"
else
    PROG=$TMP/$PROGNAME
    RT=$VIRGIL_LOC/rt
    RT_FILES=$(echo $RT/$target/*.v3 $RT/native/*.v3 $RT/gc/*.v3)
    COMPILE_ARGS="-heap-size=200m -target=$target"
    SRCS="$CORE $DIR/EnumClosureBoxing.v3"
    RUNCMD="$PROG"
fi

if [ ! -f "$PROG" ]; then
    echo "Compiling for $target..."
    $AENEAS $COMPILE_ARGS $V3C_OPTS -rt.files="$RT_FILES" -output=$TMP -program-name=$PROGNAME $SRCS
    if [ $? != 0 ]; then
        echo "Compilation failed"
        exit 1
    fi
fi

echo "EnumClosureBoxing ($target${V3C_OPTS:+, $V3C_OPTS}, ${iters} iters, best of ${RUNS}):"
echo "---"
for t in 0 1 2 3 4 5; do
    best=""
    for run in $(seq 1 $RUNS); do
        elapsed=$( { /usr/bin/time -f "%e" $RUNCMD $t $iters; } 2>&1 | tail -1 )
        if [ -z "$best" ] || [ $(echo "$elapsed < $best" | bc) = 1 ]; then
            best=$elapsed
        fi
    done
    printf "  t%d %-36s %s sec\n" $t "${labels[$t]}" "$best"
done
