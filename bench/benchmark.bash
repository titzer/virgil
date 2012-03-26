#!/bin/bash

command=$1
shift

OUT=/tmp/$USER/virgil-bench

compile() {
	echo "Compiling (jar)        $1..."
	src="$1/*.v3 Common.v3"
	if [ ! -d $OUT ]; then
		mkdir -p $OUT
	fi
	${VIRGIL_LOC}/bin/v3c -target=jar -jvm.rt-path=${VIRGIL_LOC}/rt/jvm/bin -output=$OUT $src

	echo "Compiling (x86-darwin) $1..."
	${VIRGIL_LOC}/bin/v3c -target=x86-darwin -heap-size=100M -output=$OUT ${VIRGIL_LOC}/rt/darwin/*.v3 $src
}

clean() {
	echo Cleaning $1...
	rm -f $OUT
}

if [ $# = 0 ]; then
	programs=$(echo $(ls */*.v3 | sort | cut -d/ -f1 | uniq))
else
	programs=$1
	shift
	args=$*
fi

for f in $programs; do
	if [ x$command = xcompile ]; then
		compile $f
	elif [ x$command = xclean ]; then
		clean $f
	elif [ x$command = xlist ]; then
		echo $f
	fi
done
