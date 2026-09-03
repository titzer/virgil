#!/usr/bin/env bash
# promote.bash — Promote a (minimized) bug to the permanent test suite.
#
# Copies a bug file from bugs/ into a test directory under a fresh fuzzNN
# name. For execution bugs the //@execute expectations are refreshed with
# "v3c -test -test.update" so the header reflects the reference interpreter.
#
# Usage:
#   ./promote.bash <bug.v3> [<suite>]
#
# <suite> defaults to 'core' for execution bugs, 'core/parser' for parser
# bugs, and 'core/seman' for semantic bugs.
#
# Examples:
#   ./promote.bash bugs/exec-seed42.min.v3
#   ./promote.bash bugs/parse-seed7_1.min.v3 core/parser
#   ./promote.bash bugs/exec-seed99.min.v3 variants

set -uo pipefail

FUZZ_TAG=promote
# shellcheck source=fuzz-common.bash
. "$(dirname "${BASH_SOURCE[0]}")/fuzz-common.bash"
TEST_DIR="$VIRGIL_ROOT/test"

BUG_FILE="${1:-}"
if [[ -z "$BUG_FILE" || ! -f "$BUG_FILE" ]]; then
    echo "Usage: $0 <bug.v3> [<suite>]"
    echo "Suites: core, core/parser, core/seman, variants, cast, ... (any directory under test/)"
    exit 1
fi

FIRST_LINE=$(head -1 "$BUG_FILE")
case "$FIRST_LINE" in
    "//@execute"*) DEFAULT_SUITE="core";        BUG_KIND="exec"  ;;
    "//@parse"*)   DEFAULT_SUITE="core/parser"; BUG_KIND="parse" ;;
    "//@seman"*)   DEFAULT_SUITE="core/seman";  BUG_KIND="seman" ;;
    *)
        case "$(basename "$BUG_FILE")" in
            parse-*) DEFAULT_SUITE="core/parser"; BUG_KIND="parse" ;;
            seman-*) DEFAULT_SUITE="core/seman";  BUG_KIND="seman" ;;
            *)       DEFAULT_SUITE="core";        BUG_KIND="exec"  ;;
        esac ;;
esac

SUITE="${2:-$DEFAULT_SUITE}"
DEST_DIR="$TEST_DIR/$SUITE"
if [[ ! -d "$DEST_DIR" ]]; then
    echo "ERROR: test suite directory not found: $DEST_DIR"
    exit 1
fi

# Next free fuzzNN.v3 name in the suite (fuzzNN.v3.fail counts as taken).
n=1
while ls "$DEST_DIR/fuzz$(printf '%02d' $n).v3"* >/dev/null 2>&1; do n=$((n + 1)); done
DEST_FILE="$DEST_DIR/fuzz$(printf '%02d' $n).v3"

echo "=== Promoting bug to test suite ==="
echo "Source : $BUG_FILE"
echo "Suite  : $SUITE"
echo "Kind   : $BUG_KIND"
echo "Dest   : $DEST_FILE"

# Drop the generator's banner comments and any trailing blank lines.
grep -v '^// \(This is a RANDOMLY\|Fuzzer:\|Version:\|Options:\|Seed:\)' "$BUG_FILE" | grep -v '^// *$' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' > "$DEST_FILE"

if [[ "$BUG_KIND" == "exec" ]]; then
    check_compiler
    if [[ "$(head -1 "$DEST_FILE")" != "//@execute"* ]]; then
        { make_execute_header; cat "$DEST_FILE"; } > "$DEST_FILE.tmp" && mv "$DEST_FILE.tmp" "$DEST_FILE"
    fi
    echo "[..] Refreshing //@execute expectations with the reference interpreter..."
    if ! (cd "$DEST_DIR" && "$V3C" -test -test.update "$(basename "$DEST_FILE")"); then
        echo "ERROR: the reference interpreter failed on the test; not promoting."
        rm -f "$DEST_FILE"
        exit 1
    fi
    head -1 "$DEST_FILE"
fi

echo ""
echo "[OK] Promoted to: $DEST_FILE"
echo ""
echo "Next steps:"
echo "  1. Review $DEST_FILE, add a comment describing the bug, and trim boilerplate."
echo "  2. Confirm it fails in the buggy configuration:"
echo "       cd $DEST_DIR && AENEAS_TEST=$V3C TEST_TARGETS=... ./test.bash $(basename "$DEST_FILE")"
echo "  3. Until the bug is fixed, rename it to $(basename "$DEST_FILE").fail so the suite stays green."
