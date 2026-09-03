#!/usr/bin/env bash
# Setup script for the Virgil fuzzing campaign.
# Installs Racket and the Xsmith fuzzer-generation library.
# Run once per machine before starting a campaign.

set -euo pipefail

FUZZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Virgil Fuzzing Campaign Setup ==="

# ----------------------------------------------------------------
# 1. Check / install Racket
# ----------------------------------------------------------------
if command -v racket &>/dev/null; then
    RACKET_VER=$(racket --version 2>&1 | head -1)
    echo "[OK] Racket found: $RACKET_VER"
else
    echo "[!!] Racket not found. Attempting installation..."
    case "$(uname -s)" in
        Darwin)
            if command -v brew &>/dev/null; then
                brew install minimal-racket
            else
                echo "ERROR: Homebrew not found. Install Racket from https://racket-lang.org/download/"
                exit 1
            fi
            ;;
        Linux)
            if command -v apt-get &>/dev/null; then
                sudo apt-get update && sudo apt-get install -y racket
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y racket
            else
                echo "ERROR: Cannot auto-install Racket. Download from https://racket-lang.org/download/"
                exit 1
            fi
            ;;
        *)
            echo "ERROR: Unknown OS. Install Racket from https://racket-lang.org/download/"
            exit 1
            ;;
    esac
fi

# ----------------------------------------------------------------
# 2. Install Xsmith and its dependencies via raco
#
# clotho  — provides #lang clotho (controllable randomness)
# racr    — reference attribute grammar library used by xsmith
# xsmith  — the fuzzer-generation framework
#
# We install each explicitly because minimal-racket's --auto flag
# does not always resolve transitive dependencies from the catalog.
# ----------------------------------------------------------------
install_pkg() {
    local pkg="$1"
    # raco pkg show exits 0 even for missing packages; check its output instead
    if raco pkg show "$pkg" 2>&1 | grep -q "^$pkg$\| $pkg "; then
        echo "[OK] $pkg already installed"
    else
        echo "[..] Installing $pkg..."
        raco pkg install --auto --no-docs "$pkg"
        echo "[OK] $pkg installed"
    fi
}

install_pkg clotho
install_pkg racr
install_pkg xsmith

# ----------------------------------------------------------------
# 3. Verify the virgil-smith generator runs
# ----------------------------------------------------------------
echo "[..] Testing virgil-smith generator..."
TMPOUT=$(mktemp /tmp/virgil-smith-test-XXXX)
mv "$TMPOUT" "${TMPOUT}.v3"
TMPOUT="${TMPOUT}.v3"
if racket "$FUZZ_DIR/virgil-smith/virgil-smith.rkt" --seed 1 --output-file "$TMPOUT" 2>&1; then
    echo "[OK] virgil-smith generated a test program:"
    head -3 "$TMPOUT"
    rm -f "$TMPOUT"
else
    echo "ERROR: virgil-smith failed. Check $TMPOUT for details."
    exit 1
fi

# ----------------------------------------------------------------
# 4. Check v3c / v3i are on PATH
# ----------------------------------------------------------------
if command -v v3c &>/dev/null; then
    echo "[OK] v3c found at $(command -v v3c)"
else
    echo "[!!] v3c not found on PATH. Add virgil/bin to PATH:"
    echo "     export PATH=\$PATH:$(dirname "$FUZZ_DIR")/bin"
fi

echo ""
echo "Setup complete. Run a campaign with:"
echo "  cd $FUZZ_DIR && ./run-campaign.bash"
