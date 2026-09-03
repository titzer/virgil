#!/usr/bin/env bash
# fuzz-exec.bash — Differential testing campaign for the Virgil compiler.
#
# Generates batches of random Virgil programs with virgil-smith and checks
# that every compiler configuration agrees with the reference interpreter.
#
# Per batch:
#   1. gen-batch.rkt writes N programs, each given a //@execute header that
#      lists the test inputs with placeholder expectations.
#   2. "v3c -test -test.update" runs each program in the interpreter and
#      rewrites the header with the actual results (the reference oracle).
#      Programs that fail to compile, or crash the interpreter, are bugs
#      in the generator, the semantic checker, or the interpreter.
#   3. Every other interpreter configuration (-ra, -ma=false, ...) is run
#      with "v3c -test" over the whole batch and must match the header.
#   4. For each native target and optimization level, the batch is compiled
#      with "-multiple -target=<T>-test" and executed by the standard test
#      runner (test/config/test-<T>*), which also checks against the header.
#
# Every step handles a whole batch in one or two processes, so the cost per
# program is dominated by actually running it, not by process startup.
#
# Usage:
#   ./fuzz-exec.bash [--seed S] [--batch N] [--max-depth D] [--duration SECS]
#                    [--max-programs N] [--targets "x86-64-darwin jvm wasm"]
#
# Environment:
#   FUZZ_V3C      compiler under test (must be built from current source)
#   FUZZ_TARGETS  default for --targets; "auto" probes the host
#   FUZZ_OPTS     optimization configurations for native targets
#   FUZZ_V3I_OPTS interpreter configurations to compare against the reference
#
# Terminates cleanly on CTRL+C after the current batch, printing a summary.

set -uo pipefail

FUZZ_TAG=exec
# shellcheck source=fuzz-common.bash
. "$(dirname "${BASH_SOURCE[0]}")/fuzz-common.bash"

SEED="${RANDOM}"
BATCH=50
MAX_DEPTH=5
DURATION=0
MAX_PROGRAMS=0
TARGETS="${FUZZ_TARGETS:-auto}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --seed)         SEED="$2"; shift 2 ;;
        --batch)        BATCH="$2"; shift 2 ;;
        --max-depth)    MAX_DEPTH="$2"; shift 2 ;;
        --duration)     DURATION="$2"; shift 2 ;;
        --max-programs) MAX_PROGRAMS="$2"; shift 2 ;;
        --targets)      TARGETS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Interpreter configurations compared against the plain interpreter (which
# runs at the default level, -O1).
V3I_OPTS=("-O0" "-ra" "-ra -ma=false" "-ra -maxd=4 -maxv=4" "-ra -O3" "-ra -O3 -licm")
if [[ -n "${FUZZ_V3I_OPTS:-}" ]]; then IFS='|' read -r -a V3I_OPTS <<< "$FUZZ_V3I_OPTS"; fi

# Optimization configurations for each compiled target (-O1 is the default).
OPTS=("-O0" "-O1" "-O2" "-O3" "-O2 -licm" "-O3 -licm")
if [[ -n "${FUZZ_OPTS:-}" ]]; then IFS='|' read -r -a OPTS <<< "$FUZZ_OPTS"; fi

check_compiler

WORK=$(mktemp -d "${TMPDIR:-/tmp}/virgil-fuzz-exec-XXXX")
STOP=false
trap 'STOP=true' INT TERM

programs_tested=0
programs_invalid=0
bugs_found=0
batches=0
start_time=$(date +%s)

cleanup() {
    local elapsed=$(( $(date +%s) - start_time ))
    echo ""
    echo "=== Differential Testing Summary ==="
    echo "Elapsed         : ${elapsed}s"
    echo "Batches         : $batches"
    echo "Programs tested : $programs_tested"
    echo "Invalid programs: $programs_invalid  (generator or checker problems)"
    echo "Bugs found      : $bugs_found"
    if [[ $bugs_found -gt 0 ]]; then
        echo "Bug files       : $BUGS_DIR/*.v3 (see the .log next to each)"
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

# ----------------------------------------------------------------
# Target selection: probe each candidate with a trivial program so
# that unusable toolchains (docker not running, no node, ...) are
# dropped up front instead of reporting every program as a failure.
# ----------------------------------------------------------------
probe_target() {
    local target="$1" dir="$WORK/probe"
    rm -rf "$dir"; mkdir -p "$dir"
    printf '//@execute 0=0; 1=2; -1=-2\ndef main(a: int) -> int { return a * 2; }\n' > "$dir/probe.v3"
    local results="$dir/results"
    (cd "$dir" && run_target_batch "$target" "" "$dir/out" "$results" probe.v3) 2>/dev/null
    # Usable only if the runner actually reported a pass (an absent or broken
    # runner, e.g. docker not running, produces no ##-ok at all).
    [[ -f "$results" && ! -s "$results" ]] && grep -q '^##-ok' "$results.run.raw" 2>/dev/null
}

if [[ "$TARGETS" == "auto" ]]; then
    candidates="x86-64-linux arm64-linux x86-linux x86-64-darwin x86-darwin jvm wasm"
    TARGETS=""
    for t in $candidates; do
        find_runner "$t" >/dev/null || continue
        if probe_target "$t"; then TARGETS="$TARGETS $t"; else warn "target $t: runner present but probe failed; skipping"; fi
    done
    TARGETS="${TARGETS# }"
else
    for t in $TARGETS; do
        probe_target "$t" || warn "target $t: probe failed; expect failures"
    done
fi

info "Starting differential testing campaign"
info "Compiler : $V3C"
info "Seed     : $SEED   batch=$BATCH   max-depth=$MAX_DEPTH"
info "Inputs   : $FUZZ_INPUTS"
info "Targets  : ${TARGETS:-none}"
info "Opts     : $(printf '[%s] ' "${OPTS[@]}")"
info "v3i opts : $(printf '[%s] ' "${V3I_OPTS[@]}")"
info "Bugs dir : $BUGS_DIR"
[[ $DURATION -gt 0 ]] && info "Duration : ${DURATION}s"
info "Press CTRL+C to stop."
echo ""

# ----------------------------------------------------------------
# One batch. Failures are accumulated per file in $FAILS (a file of
# "<name>\t<config>\t<message>" lines) so that a program that fails in
# several configurations is saved once, with all of them in its log.
# ----------------------------------------------------------------
run_batch() {
    local seed="$1" count="$2"
    local dir="$WORK/batch"
    rm -rf "$dir"; mkdir -p "$dir"
    local FAILS="$dir/fails"; : > "$FAILS"

    # 1. Generate.
    racket "$GEN_BATCH" --seed "$seed" --count "$count" --max-depth "$MAX_DEPTH" --out-dir "$dir" 2> "$dir/gen.err"
    if [[ -s "$dir/gen.err" ]]; then warn "generator: $(head -3 "$dir/gen.err")"; fi
    cd "$dir" || return 1
    local files=()
    for f in prog_*.v3; do [[ -f "$f" ]] && { add_execute_header "$f"; files+=("$f"); }; done
    [[ ${#files[@]} -eq 0 ]] && { warn "no programs generated for seed $seed"; return 1; }
    programs_tested=$((programs_tested + ${#files[@]}))

    # 2. Reference run: fills in the expectations.
    run_v3c_test_batch "-test.update" "$dir/ref.results" "${files[@]}"
    local valid=()
    for f in "${files[@]}"; do
        local line
        line=$(grep "^${f%.v3}"$'\t' "$dir/ref.results" | head -1)
        local st; st=$(echo "$line" | cut -f2)
        local msg; msg=$(echo "$line" | cut -f3-)
        case "$st" in
            ok) valid+=("$f") ;;
            fail)
                # A compile error: the generator emitted an invalid program,
                # or the checker rejected a valid one. Not comparable; save it
                # separately so the generator can be fixed.
                programs_invalid=$((programs_invalid + 1))
                printf '%s\tv3i\tinvalid: %s\n' "${f%.v3}" "$msg" >> "$FAILS"
                ;;
            *)  printf '%s\tv3i\tcrash: %s\n' "${f%.v3}" "$msg" >> "$FAILS" ;;
        esac
    done

    if [[ ${#valid[@]} -gt 0 ]]; then
        # 3. Interpreter configurations.
        for opts in "${V3I_OPTS[@]}"; do
            run_v3c_test_batch "$opts" "$dir/v3i.results" "${valid[@]}"
            awk -F'\t' -v OFS='\t' -v cfg="v3i $opts" '$2 != "ok" { print $1, cfg, $2 ": " $3 }' "$dir/v3i.results" >> "$FAILS"
        done
        # 4. Compiled targets. Each (target, opts) pair is independent, so
        #    they run concurrently; the native tester dominates the batch time.
        local jobs=() i=0
        for t in $TARGETS; do
            for opts in "${OPTS[@]}"; do
                i=$((i + 1))
                run_target_batch "$t" "$opts" "$dir/out-$i" "$dir/target-$i.results" "${valid[@]}" &
                jobs+=($!)
            done
        done
        wait "${jobs[@]}" 2>/dev/null
        i=0
        for t in $TARGETS; do
            for opts in "${OPTS[@]}"; do
                i=$((i + 1))
                awk -F'\t' -v OFS='\t' -v cfg="$t $opts" '{ print $1, cfg, $2 ": " $3 }' "$dir/target-$i.results" >> "$FAILS"
            done
        done
    fi

    # 5. Save every failing program once.
    local failing
    failing=$(cut -f1 "$FAILS" | sort -u)
    for n in $failing; do
        local pseed="${n#prog_}"
        local log; log=$(awk -F'\t' -v n="$n" '$1 == n { printf "  [%s] %s\n", $2, $3 }' "$FAILS")
        local kind=exec
        if echo "$log" | grep -q 'invalid:'; then kind=invalid; fi
        if echo "$log" | grep -q '^  \[v3i\] crash'; then kind=v3i-crash; fi
        if echo "$log" | grep -q 'compile: '; then kind=compile; fi
        local saved
        saved=$(save_bug "$kind" "$pseed" "$n.v3" "failures:"$'\n'"$log")
        if [[ "$kind" == invalid ]]; then
            warn "invalid program seed=$pseed: $(echo "$log" | head -1 | sed 's/^ *//')"
        else
            bugs_found=$((bugs_found + 1))
            bug "seed=$pseed saved to $saved"
            echo "$log" >&2
        fi
    done
    cd "$WORK" || true
}

# ----------------------------------------------------------------
# Main campaign loop
# ----------------------------------------------------------------
seed=$SEED
while [[ "$STOP" == false ]]; do
    if [[ $DURATION -gt 0 && $(( $(date +%s) - start_time )) -ge $DURATION ]]; then break; fi
    if [[ $MAX_PROGRAMS -gt 0 && $programs_tested -ge $MAX_PROGRAMS ]]; then break; fi
    run_batch "$seed" "$BATCH"
    batches=$((batches + 1))
    seed=$((seed + BATCH))
    info "batch $batches done: $programs_tested programs, $bugs_found bugs, $programs_invalid invalid, $(( $(date +%s) - start_time ))s elapsed (next seed=$seed)"
done
