#!/bin/bash
export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)
export S=$VIRGIL_TEST/scripts

cd $VIRGIL_TEST/exe/

. ../common.bash exe

DIRS="core variants"

# parallel tests
function compile_all_targets() {
    MAX=16
    i=3
    for target in $TEST_TARGETS; do
	if [ -x $S/compile-exe-${target}.bash ]; then
	    FIFO=$OUT/$target.compile.fifo
	    F=$OUT/$i.fifo
	    rm -f $FIFO $F
	    mkfifo $FIFO
	    ln -s $FIFO $F
	    $S/compile-exe-jvm.bash "$@" > $FIFO &
	    i=$(($i + 1))
	fi
    done

    # pad the rest of the fifos
    while [ $i -le $MAX ]; do
	F=$OUT/$i.fifo
	rm -f $F
	echo > $F
	i=$(($i + 1))
    done
    
    # yuck! stupid bash.
    progress p 3<$OUT/3.fifo 4<$OUT/4.fifo 5<$OUT/5.fifo 6<$OUT/6.fifo 7<$OUT/7.fifo 8<$OUT/8.fifo 9<$OUT/9.fifo 10<$OUT/10.fifo 11<$OUT/11.fifo 12<$OUT/12.fifo 13<$OUT/13.fifo 14<$OUT/14.fifo 15<$OUT/15.fifo 16<$OUT/16.fifo
}

compile_all_targets ../core/*.v3

exit 0

# serial tests
for dir in $DIRS; do

    for target in $TEST_TARGETS; do
	if [ -x $S/compile-exe-${target}.bash ]; then
	    print_status "Compiling" $target $dir
	    $S/compile-exe-${target}.bash $dir/*.v3 | $PROGRESS
	fi
	
	print_status "Running" $target $dir
	if [ -x $S/run-exe-${target}.bash ]; then
	    $S/run-exe-${target}.bash $dir/*.v3 | $PROGRESS
	else
	    echo "Skipped"
	fi
    done

done
