#!/bin/bash

function line() {
    echo ================================================================================
}

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

if [ $# != 3 ]; then
    echo "Usage: check-bootstrap.bash <target> <Aeneas before> <Aeneas after>"
    exit 1
fi

BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

target=$1
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

echo -n "" > $TMP/diff

line
echo -e "${BLUE}$before -output=$OUT_BEFORE -multiple -target=$target $DIR/execute/*.v3${NC}"
$before -output=$OUT_BEFORE -multiple -target=$target $DIR/execute/*.v3 &> /dev/null

line
echo -e "${BLUE}$after -output=$OUT_AFTER -multiple -target=$target $DIR/execute/*.v3${NC}"
$after -output=$OUT_AFTER -multiple -target=$target $DIR/execute/*.v3 &> /dev/null

line
echo -e "${BLUE}diff -d $OUT_BEFORE $OUT_AFTER${NC}"
DIFF=$(diff -d $OUT_BEFORE $OUT_AFTER)

set -f
IFS=$'\n'
for l in $DIFF; do
    file=$(echo $l | awk '{ print $3 }')
    echo -n $(wc -c $file | awk '{ print $1 }') "" >> $TMP/diff
    echo $l >> $TMP/diff
done

echo -e "${GREEN}Smallest binaries as per $TMP/diff${NC}:"
sort -n $TMP/diff | head
