#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.bash compare

if [ $# != 4 ]; then
    echo "Usage: compare.bash <target> <one test> <Aeneas before> <Aeneas after>"
    exit 1
fi

target=$1
TEST=$2
TEST_NO_EXT=${2%*.*}
before=$3
after=$4

OUT_BEFORE=$OUT/before
OUT_AFTER=$OUT/after

mkdir -p $OUT_BEFORE
mkdir -p $OUT_AFTER

line
echo -e "${BLUE}$before -print-ssa -print-mach -target=$target $TEST${NORM}"
$before -print-ssa -print-mach -print-bin -target=$target $TEST &> $OUT/before.out

line
echo -e "${BLUE}$after -print-ssa -print-mach -target=$target $TEST${NORM}"
$after -print-ssa -print-mach -print-bin -target=$target $TEST &> $OUT/after.out

line
echo -e "${BLUE}diff -u $OUT/before.out $OUT/after.out${NORM}"
diff -u --color=always $OUT/before.out $OUT/after.out
