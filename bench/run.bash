#!/bin/bash

TMP=/tmp/$USER/virgil-bench/

if [ -z "$RUN_COUNT" ]; then
	COUNT=5
else
	COUNT=$RUN_COUNT
fi

if [ $# = 0 ]; then
	echo "Usage: run [tiny|small|large|huge] <engines>"
	exit 1
fi

size=$1
shift

if [ $# = 0 ]; then
	engines="aeneas"
else
	engines="$1"
	shift
fi

if [ $# = 0 ]; then
	programs=$(echo $(ls */*.v3 | sort | cut -d/ -f1 | uniq))
else
	programs="$*"
	shift
fi

mkdir -p $TMP

if [ ! -x $TMP/btime ]; then
	echo Compiling btime.c...
	gcc -O2 -o $TMP/btime btime.c
fi

for p in $programs; do
	if [ ! -f "$p/args-$size" ]; then
		continue
	fi

	args=$(cat $p/args-$size)
	for e in $engines; do
		printf "$p ($size): "

		flags=""
		if [ -f $p/flags-$e ]; then
			flags=$(cat $p/flags-$e)
		fi

		files="Common.v3 $p/$p.v3"
		if [ -x "$p/$p.bash" ]; then
			files=$($p/$p.bash $TMP)
		fi

		COMMAND=$(./target-$e $TMP "$p" "$flags" "$files")

		if [ $? = 0 ]; then
			printf "$COMMAND $args\n"
			$TMP/btime $TMP/$p-$e $COUNT $COMMAND $args
		else
			echo "  Failed compiling ($e) $p"
		fi
	done
done
