#!/usr/bin/env bash
# fuzz-parser.bash — Parser and semantic checker crash finder.
#
# Takes valid programs from virgil-smith (generated in batches) and applies
# random text-level mutations, then feeds each mutant to "v3c -test":
#
#   syntax mode (//@parse):  delete/duplicate lines, replace identifiers
#                            with keywords, insert tokens, swap characters.
#   type mode   (//@seman):  replace type annotations with wrong types,
#                            plus a few structural mutations.
#
# Mutants are expected to be rejected with a diagnostic. A bug is any of:
#   - the compiler exits with a signal (SIGSEGV, SIGABRT, ...)
#   - the compiler prints an internal error
#   - the compiler hangs (timeout)
#
# Usage:
#   ./fuzz-parser.bash [--seed SEED] [--batch N] [--duration SECS] [--max-programs N]
#
# Environment:
#   FUZZ_V3C   compiler under test

set -uo pipefail

FUZZ_TAG=parse
# shellcheck source=fuzz-common.bash
. "$(dirname "${BASH_SOURCE[0]}")/fuzz-common.bash"

SEED="${RANDOM}"
BATCH=50
DURATION=0
MAX_PROGRAMS=0
COMPILE_TIMEOUT=10
while [[ $# -gt 0 ]]; do
    case "$1" in
        --seed)         SEED="$2"; shift 2 ;;
        --batch)        BATCH="$2"; shift 2 ;;
        --duration)     DURATION="$2"; shift 2 ;;
        --max-programs) MAX_PROGRAMS="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

check_compiler
WORK=$(mktemp -d "${TMPDIR:-/tmp}/virgil-fuzz-parser-XXXX")
STOP=false
trap 'STOP=true' INT TERM

programs_tested=0
bugs_found=0
start_time=$(date +%s)

cleanup() {
    echo ""
    echo "=== Parser/Seman Fuzzing Summary ==="
    echo "Elapsed         : $(( $(date +%s) - start_time ))s"
    echo "Programs tested : $programs_tested"
    echo "Bugs found      : $bugs_found"
    if [[ $bugs_found -gt 0 ]]; then
        echo "Bug files       : $BUGS_DIR/parse-*.v3  $BUGS_DIR/seman-*.v3"
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT

# Run the compiler in test mode on one mutant. Prints a description of the
# problem and returns 1 if a crash, internal error, or hang was detected.
check_mutant() {
    local prog="$1" outfile="$WORK/compiler_out"
    with_timeout "$COMPILE_TIMEOUT" "$V3C" -test "$prog" > "$outfile" 2>&1
    local rc=$?
    if [[ $rc -eq 142 ]]; then echo "timeout after ${COMPILE_TIMEOUT}s"; return 1; fi
    if [[ $rc -gt 128 ]]; then echo "signal $((rc - 128))"; return 1; fi
    if [[ $rc -gt 1 ]]; then echo "exit code $rc: $(tail -1 "$outfile")"; return 1; fi
    if grep -qiE '(internal error|InternalError|assertion failed|fatal:|stack overflow|!Unimplemented|!NullCheck|!BoundsCheck)' "$outfile"; then
        echo "internal error: $(grep -iE '(internal error|InternalError|assertion|fatal|overflow|!Unimplemented|!NullCheck|!BoundsCheck)' "$outfile" | head -1)"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------
# Mutations. Each takes a file path and mutates it in place. Line 1 is
# the //@parse or //@seman directive and is never touched.
# ---------------------------------------------------------------
rand_line() {   # a random non-blank line number >= 2 (0 if none)
    local candidates
    candidates=$(awk 'NR >= 2 && NF > 0 { print NR }' "$1")
    [[ -z "$candidates" ]] && { echo 0; return; }
    local arr=($candidates)
    echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

mutate_delete_line() {
    local f="$1" n; n=$(rand_line "$f"); [[ $n -eq 0 ]] && return
    sed -i '' "${n}d" "$f"
}

mutate_dup_line() {
    local f="$1" n; n=$(rand_line "$f"); [[ $n -eq 0 ]] && return
    sed -i '' "${n}{p;}" "$f"
}

mutate_replace_id() {
    local f="$1"
    local keywords=("class" "component" "def" "var" "if" "else" "while" "for"
                    "return" "true" "false" "null" "type" "enum" "match" "layout"
                    "new" "extends" "private" "break" "continue" "in" "int" "void" "main")
    local kw="${keywords[$((RANDOM % ${#keywords[@]}))]}"
    local n; n=$(rand_line "$f"); [[ $n -eq 0 ]] && return
    local k=$((RANDOM % 6 + 1))
    # Replace the k-th identifier on line n with the keyword.
    perl -i -pe 'if ($. == '"$n"') { my $c = 0; s/\b([a-zA-Z_][a-zA-Z0-9_]*)\b/(++$c == '"$k"') ? "'"$kw"'" : $1/ge; }' "$f"
}

mutate_insert_token() {
    local f="$1"
    local tokens=("(" ")" "{" "}" "[" "]" ";" ":" "." "," "=" "=>" "->" "<" ">" "+" "-"
                  "*" "/" "%" "&&" "||" "!" "&" "|" "^" "<<" ">>" "?" "#" "'" "\"" "0x" "1L"
                  "class" "def" "var" "return" "if" "null" "0" "true" "match" "type" "T" "int.!(" "Array<int>.new(")
    local tok="${tokens[$((RANDOM % ${#tokens[@]}))]}"
    local n; n=$(rand_line "$f"); [[ $n -eq 0 ]] && return
    local col=$((RANDOM % 40))
    # Insert the token at column col (or at end of line if shorter).
    TOK="$tok" perl -i -pe 'if ($. == '"$n"') { my $p = '"$col"'; $p = length($_) - 1 if $p > length($_) - 1; substr($_, $p, 0) = $ENV{TOK}; }' "$f"
}

mutate_swap_chars() {
    local f="$1"
    local size; size=$(wc -c < "$f")
    [[ $size -lt 10 ]] && return
    local first; first=$(head -1 "$f" | wc -c)
    local p1=$(( first + (RANDOM % (size - first - 2)) ))
    local p2=$(( p1 + 1 + (RANDOM % 20) ))
    [[ $p2 -ge $size ]] && p2=$((size - 1))
    perl -e 'local $/; open F, "<", $ARGV[0]; my $d = <F>; close F;
             my ($a, $b) = ($ARGV[1], $ARGV[2]);
             if ($b < length $d) { my $t = substr($d,$a,1); substr($d,$a,1) = substr($d,$b,1); substr($d,$b,1) = $t; }
             open F, ">", $ARGV[0]; print F $d; close F;' "$f" "$p1" "$p2"
}

rand_body_line() {   # a random non-blank line inside the method body
    local candidates
    candidates=$(awk 'NR >= 2 && NF > 0 && !/^def / { print NR }' "$1")
    [[ -z "$candidates" ]] && { echo 0; return; }
    local arr=($candidates)
    echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

mutate_wrong_type() {
    local f="$1"
    local types=("bool" "long" "Array<int>" "(int, int)" "void" "byte" "u32" "i64" "float" "string" "Range<int>" "int -> int" "T" "Array<Array<bool>>")
    local t="${types[$((RANDOM % ${#types[@]}))]}"
    local n; n=$(rand_body_line "$f"); [[ $n -eq 0 ]] && return
    perl -i -pe 'if ($. == '"$n"') { s/\bint\b/'"$t"'/; }' "$f"
}

# Wrong operand type: wrap an int expression in a bool/long/etc. context.
mutate_wrong_expr() {
    local f="$1"
    local wraps=("!(\1)" "(\1).length" "(\1)[0]" "(\1).0" "long.!(\1) + \1" "if(\1, 0, 1)" "(\1)(0)" "(\1) == true" "(\1).foo" "(\1)++" "-(\1) && \1")
    local w="${wraps[$((RANDOM % ${#wraps[@]}))]}"
    local n; n=$(rand_body_line "$f"); [[ $n -eq 0 ]] && return
    # Pick a variable name or literal (not a keyword) as the victim.
    perl -i -pe 'if ($. == '"$n"') { s/\b(?!(?:def|return|if|var|for|int|long|true|false|main|view)\b)([a-z][a-zA-Z0-9_]*|[0-9]+L?)\b/'"${w//\\1/\$1}"'/; }' "$f"
}

apply_mutations() {
    local src="$1" dst="$2" count="$3" mode="$4"
    if [[ "$mode" == "syntax" ]]; then
        { echo "//@parse"; grep -v '^//' "$src"; } > "$dst"
        local mutations=("delete_line" "dup_line" "replace_id" "insert_token" "swap_chars")
    else
        { echo "//@seman"; grep -v '^//' "$src"; } > "$dst"
        local mutations=("wrong_type" "wrong_expr" "wrong_expr" "delete_line" "replace_id" "insert_token")
    fi
    for _ in $(seq 1 "$count"); do
        "mutate_${mutations[$((RANDOM % ${#mutations[@]}))]}" "$dst"
    done
}

# ---------------------------------------------------------------
# Main loop: generate a batch of base programs, then several mutants each.
# ---------------------------------------------------------------
info "Starting parser/seman fuzzing"
info "Compiler : $V3C"
info "Seed     : $SEED   batch=$BATCH"
info "Bugs dir : $BUGS_DIR"
[[ $DURATION -gt 0 ]] && info "Duration : ${DURATION}s"
info "Press CTRL+C to stop."
echo ""

RANDOM=$SEED
seed=$SEED
while [[ "$STOP" == false ]]; do
    if [[ $DURATION -gt 0 && $(( $(date +%s) - start_time )) -ge $DURATION ]]; then break; fi
    if [[ $MAX_PROGRAMS -gt 0 && $programs_tested -ge $MAX_PROGRAMS ]]; then break; fi

    dir="$WORK/batch"; rm -rf "$dir"; mkdir -p "$dir"
    racket "$GEN_BATCH" --seed "$seed" --count "$BATCH" --out-dir "$dir" 2>/dev/null
    for base in "$dir"/prog_*.v3; do
        [[ "$STOP" == true ]] && break
        [[ -f "$base" ]] || continue
        bseed="${base##*/prog_}"; bseed="${bseed%.v3}"
        for k in 1 2 3 4; do
            if (( (bseed + k) % 3 == 0 )); then mode=type; nmut=$((1 + RANDOM % 3)); else mode=syntax; nmut=$((1 + RANDOM % 5)); fi
            mut="$dir/mut_${bseed}_$k.v3"
            apply_mutations "$base" "$mut" "$nmut" "$mode"
            programs_tested=$((programs_tested + 1))
            problem=$(check_mutant "$mut")
            if [[ -n "$problem" ]]; then
                bugs_found=$((bugs_found + 1))
                kind=parse; [[ "$mode" == type ]] && kind=seman
                saved=$(save_bug "$kind" "${bseed}_$k" "$mut" "mode: $mode ($nmut mutations)"$'\n'"problem: $problem")
                bug "$problem — saved to $saved"
            fi
        done
    done
    seed=$((seed + BATCH))
    info "$programs_tested mutants tested, $bugs_found bugs, $(( $(date +%s) - start_time ))s elapsed (next seed=$seed)"
done
