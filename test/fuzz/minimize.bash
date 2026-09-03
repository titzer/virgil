#!/usr/bin/env bash
# minimize.bash — Minimize a failing Virgil test case by line-level delta
# debugging, keeping the failure reproducible in one configuration.
#
# For execution (miscompilation) bugs the configuration is a target name
# followed by compiler options, exactly as printed in the bug's .log:
#   ./minimize.bash exec "x86-64-darwin -O2" bugs/exec-seed42.v3
#   ./minimize.bash exec "v3i -ra -ma=false" bugs/exec-seed42.v3
# The oracle refreshes the //@execute expectations of each candidate with
# "v3c -test -test.update" (so the reference interpreter always agrees with
# the header) and then checks that the configuration still disagrees.
#
# For parser/semantic crashes:
#   ./minimize.bash parse bugs/parse-seed7_1.v3
#   ./minimize.bash seman bugs/seman-seed7_1.v3
#
# Writes <bug>.min.v3 next to the input.

set -uo pipefail

FUZZ_TAG=minimize
# shellcheck source=fuzz-common.bash
. "$(dirname "${BASH_SOURCE[0]}")/fuzz-common.bash"

MODE="${1:-}"
case "$MODE" in
    exec)         CONFIG="${2:-}"; BUG_FILE="${3:-}" ;;
    parse|seman)  CONFIG="";       BUG_FILE="${2:-}" ;;
    *)
        echo "Usage:"
        echo "  $0 exec \"<target> [opts]\" <bug.v3>   # miscompilation, e.g. \"x86-64-darwin -O2\" or \"v3i -ra\""
        echo "  $0 parse <bug.v3>                     # parser crash"
        echo "  $0 seman <bug.v3>                     # semantic checker crash"
        exit 1 ;;
esac
if [[ ! -f "$BUG_FILE" ]]; then echo "ERROR: file not found: $BUG_FILE"; exit 1; fi
if [[ "$MODE" == exec && -z "$CONFIG" ]]; then echo "ERROR: exec mode needs a configuration"; exit 1; fi
check_compiler

WORK=$(mktemp -d "${TMPDIR:-/tmp}/virgil-minimize-XXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/t"

TARGET="${CONFIG%% *}"
OPTS=""; [[ "$CONFIG" == *" "* ]] && OPTS="${CONFIG#* }"

# ---------------------------------------------------------------
# Oracle: returns 0 if the failure is still present in the candidate.
# ---------------------------------------------------------------
still_fails() {
    local f="$1" name="cand.v3"
    cp "$f" "$WORK/t/$name"
    cd "$WORK/t" || return 1
    case "$MODE" in
        exec)
            # The reference must compile and run the candidate cleanly.
            run_v3c_test_batch "-test.update" "ref.results" "$name"
            grep -q $'\tok\t' ref.results || { cd - >/dev/null; return 1; }
            if [[ "$TARGET" == v3i ]]; then
                run_v3c_test_batch "$OPTS" "cfg.results" "$name"
                ! grep -q $'\tok\t' cfg.results
            else
                run_target_batch "$TARGET" "$OPTS" "$WORK/t/out" "cfg.results" "$name" 2>/dev/null
                [[ -s cfg.results ]]
            fi
            ;;
        parse|seman)
            local out; out=$(with_timeout 10 "$V3C" -test "$name" 2>&1); local rc=$?
            [[ $rc -gt 1 ]] && return 0      # signal, timeout, or abnormal exit
            echo "$out" | grep -qiE '(internal error|InternalError|assertion|fatal:|!Unimplemented|!NullCheck|!BoundsCheck)'
            ;;
    esac
    local r=$?
    cd - >/dev/null
    return $r
}

WORKFILE="$WORK/work.v3"
cp "$BUG_FILE" "$WORKFILE"
if ! still_fails "$WORKFILE"; then
    info "WARNING: the original file does not reproduce the failure in configuration '$CONFIG'."
    info "Check the .log next to the bug for the configurations that failed."
    exit 1
fi

lines_before=$(wc -l < "$WORKFILE")
info "Minimizing $BUG_FILE ($lines_before lines), mode=$MODE config='$CONFIG'"

# ---------------------------------------------------------------
# Delta debugging: try removing chunks of lines, halving the chunk size
# until single lines; line 1 (the test directive) is never removed.
# ---------------------------------------------------------------
try_remove() {   # try_remove FROM COUNT -> 0 if removed
    local from="$1" count="$2" cand="$WORK/cand.v3"
    awk -v a="$from" -v b="$((from + count - 1))" 'NR < a || NR > b' "$WORKFILE" > "$cand"
    if still_fails "$cand"; then cp "$cand" "$WORKFILE"; return 0; fi
    return 1
}

total=$(wc -l < "$WORKFILE")
chunk=$(( (total - 1) / 2 )); [[ $chunk -lt 1 ]] && chunk=1
while [[ $chunk -ge 1 ]]; do
    n=2
    while [[ $n -le $total ]]; do
        c=$chunk; [[ $((n + c - 1)) -gt $total ]] && c=$((total - n + 1))
        if try_remove "$n" "$c"; then
            total=$((total - c))
            info "removed $c line(s) at $n (now $total lines)"
        else
            n=$((n + c))
        fi
    done
    [[ $chunk -eq 1 ]] && break
    chunk=$((chunk / 2))
done

# A final pass that tries to simplify individual lines by deleting one
# parenthesized subexpression at a time (helps with the generator's long
# single-line expressions).
simplify_line() {   # simplify_line N -> 0 if the line got shorter
    local n="$1" cand="$WORK/cand.v3"
    local line; line=$(sed -n "${n}p" "$WORKFILE")
    local i=0 len=${#line}
    while [[ $i -lt $len ]]; do
        if [[ "${line:$i:1}" == "(" ]]; then
            # find the matching close paren
            local depth=0 j=$i
            while [[ $j -lt $len ]]; do
                case "${line:$j:1}" in "(") depth=$((depth + 1)) ;; ")") depth=$((depth - 1)) ;; esac
                [[ $depth -eq 0 ]] && break
                j=$((j + 1))
            done
            if [[ $j -gt $((i + 1)) ]]; then
                # try replacing "(...)" by "0", then by its own contents
                for repl in "0" "${line:$((i + 1)):$((j - i - 1))}"; do
                    local newline="${line:0:$i}${repl}${line:$((j + 1))}"
                    awk -v n="$n" -v l="$newline" 'NR == n { print l; next } { print }' "$WORKFILE" > "$cand"
                    if still_fails "$cand"; then cp "$cand" "$WORKFILE"; return 0; fi
                done
            fi
        fi
        i=$((i + 1))
    done
    return 1
}
n=2
while [[ $n -le $total ]]; do
    if simplify_line "$n"; then info "simplified line $n"; else n=$((n + 1)); fi
done

MIN_FILE="${BUG_FILE%.v3}.min.v3"
cp "$WORKFILE" "$MIN_FILE"
echo ""
echo "=== Minimization complete ==="
echo "Original : $BUG_FILE  ($lines_before lines)"
echo "Minimized: $MIN_FILE  ($(wc -l < "$MIN_FILE") lines)"
echo ""
cat "$MIN_FILE"
