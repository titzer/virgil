#!/bin/bash

TMP=/tmp/$USER/virgil-bench/

if [ -z "$RUN_COUNT" ]; then
	COUNT=5
else
	COUNT=$RUN_COUNT
fi

if [ $# = 0 ]; then
	echo "Usage: compile <targets> [benchmarks]"
	exit 1
fi

targets="$1"
shift

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
	for t in $targets; do
		printf "$p ($t): "

		files="Common.v3 $p/$p.v3"
		if [ -x "$p/$p.bash" ]; then
			files=$($p/$p.bash $TMP)
		fi

		COMMAND="$(which v3c-$t) -output=$TMP $files"

		if [ $? = 0 ]; then
			printf "$COMMAND $args\n"
		else
			echo "  Failed compiling ($t) $p"
		fi
		$TMP/btime $TMP/$p-$t $COUNT $COMMAND
	done
done
