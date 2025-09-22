#!/usr/bin/env bash

if [ $# -eq 0 ]; then
	echo "Usage: build <benchmark>"
	exit 1
fi

if [ ! -d "$1" ]; then
	echo "Usage: build <benchmark>"
	exit 1
fi

C_FILES="$(ls $1/*.c)"
V3_FILES="$(ls $1/*.v3)"

TMP_DIR=/tmp/$USER/virgil-bench/$1

mkdir -p $TMP_DIR/c
mkdir -p $TMP_DIR/v3

for f in $C_FILES; do
	b=$(basename $f)
	b=${b%*.*}
	echo Compiling $TMP_DIR/c/$b...
	gcc -m32 -o $TMP_DIR/c/$b $f
done

for f in $V3_FILES; do
	b=$(basename $f)
	b=${b%*.*}
	echo Compiling $TMP_DIR/v3/$b...
	aeneas -target=x86-darwin -output=$TMP_DIR/v3 $f
done
