#!/bin/bash

function line() {
    echo ================================================================================
}

if [ $# != 4 ]; then
    echo "Usage: compare.bash <target> <one test> <Aeneas before> <Aeneas after>"
    exit 1
fi

BLUE='\033[0;34m'
NC='\033[0m'

target=$1
shift

TEST=$1
TEST_NO_EXT=${1%*.*}
shift

before=$1
shift

after=$1
shift

TMP=/tmp/$USER

OUT_BEFORE=$TMP/before
OUT_AFTER=$TMP/after

mkdir -p $OUT_BEFORE
mkdir -p $OUT_AFTER

line
echo -e "${BLUE}$before -print-ssa -print-mach -target=$target $TEST${NC}"
$before -print-ssa -print-mach -print-bin -target=$target $TEST &> $TMP/before.out

line
echo -e "${BLUE}$after -print-ssa -print-mach -target=$target $TEST${NC}"
$after -print-ssa -print-mach -print-bin -target=$target $TEST &> $TMP/after.out

line
echo -e "${BLUE}diff -u $TMP/before.out $TMP/after.out${NC}"
diff -u $TMP/before.out $TMP/after.out
