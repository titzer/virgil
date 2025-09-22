#!/usr/bin/env bash

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  echo "Usage: ./gen.bash <test.v3>"
fi

function gen_input() {
	t=$1

	pipein=$(mktemp -u)
	pipeout=$(mktemp -u)
	mkfifo $pipein
	mkfifo $pipeout

	tail -f $pipein | v3c -debug -debug-extension $t > $pipeout 2> /dev/null & 
	tailpid=$(($!-1))

	infile=${t##*/}.in
	> $infile

	# set breakpoints on return
	for line in $(grep -n 'return' $t | cut -d ':' -f 1)
	do
		echo "b $t $line" >> $infile
		echo "b $t $line" > $pipein
	done

	echo -e "run" > $pipein
	echo -e "run" >> $infile

	while read row
	do
		if [ "${row}" = "end" ]; then
			echo "q" >> $infile
			echo "q" > $pipein
			break
		fi
		if [[ $row == stop* ]]; then
			echo -e "c" > $pipein
			echo -e "bt\ninfo l\nc" >> $infile
		fi
	done < $pipeout

	kill $tailpid
	rm $pipein
	rm $pipeout
}

function gen_output() {
	t=$1
	infile=${t##*/}.in
	outfile=${t##*/}.out
	v3c -debug -debug-extension $t < $infile > $outfile
}

function gen() {
	for t in $@; do
		echo generating $t
		gen_input $t
		gen_output $t
	done
}

gen $TESTS
