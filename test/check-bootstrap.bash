#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.bash check-bootstrap

if [ $# -lt 3 ]; then
    echo "Usage: check-bootstrap.bash <target> <Aeneas before> <Aeneas after>"
    exit 1
fi

target=$1
shift

before=$1
shift

after=$1
shift

OUT_BEFORE=$OUT/before
OUT_AFTER=$OUT/after
DIFF_FILE=$OUT/diff

mkdir -p $OUT_BEFORE
mkdir -p $OUT_AFTER
echo -n "" > $DIFF_FILE

shopt -s nullglob
if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=($DIR/*.v3)
fi

if [ ${#TESTS[@]} == 0 ]; then
    echo -e "${RED}No tests given${NORM}"
    exit 1
fi

line
echo -e "${BLUE}$before -output=$OUT_BEFORE -multiple -target=$target TESTS${NORM}"
$before -output=$OUT_BEFORE -multiple -target=$target $TESTS &> /dev/null

line
echo -e "${BLUE}$after -output=$OUT_AFTER -multiple -target=$target TESTS${NORM}"
$after -output=$OUT_AFTER -multiple -target=$target $TESTS &> /dev/null

line
echo -e "${BLUE}diff -d $OUT_BEFORE $OUT_AFTER${NORM}"
DIFF=$(diff -d $OUT_BEFORE $OUT_AFTER)

set -f
IFS=$'\n'
for l in $DIFF; do
    file=$(echo $l | awk '{ print $3 }')
    echo -n $(wc -c $file | awk '{ print $1 }') "" >> $DIFF_FILE
    echo $l >> $DIFF_FILE
done

echo -e "${GREEN}Smallest binaries as per $DIFF_FILE${NORM}:"
sort -n $DIFF_FILE | head
