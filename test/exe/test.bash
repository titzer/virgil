#!/bin/bash
export VIRGIL_TEST=$(builtin cd $(dirname ${BASH_SOURCE[0]}) && builtin cd .. && builtin pwd)
export S=$VIRGIL_TEST/scripts

cd $VIRGIL_TEST/exe/

. ../common.bash exe

DIRS="core variants"

# parallel tests
function do_parallel() {
    action=$1
    shift
    MAX=16
    i=3
    for target in $TEST_TARGETS; do
	if [ -x $S/${action}-exe-${target}.bash ]; then
	    FIFO=$OUT/$target.compile.fifo
	    F=$OUT/$i.fifo
	    rm -f $FIFO $F
	    mkfifo $FIFO
	    ln -s $FIFO $F
	    $S/${action}-exe-${target}.bash "$@" > $FIFO &
	    i=$(($i + 1))
	fi
    done
    n=$(($i - 3))
    
    # pad the rest of the fifos
    while [ $i -le $MAX ]; do
	F=$OUT/$i.fifo
	rm -f $F
	echo > $F
	i=$(($i + 1))
    done
    
    # yuck! stupid bash.
    printf "Running ${action} ($n processes): "
    progress ip 3<$OUT/3.fifo 4<$OUT/4.fifo 5<$OUT/5.fifo 6<$OUT/6.fifo 7<$OUT/7.fifo 8<$OUT/8.fifo 9<$OUT/9.fifo 10<$OUT/10.fifo 11<$OUT/11.fifo 12<$OUT/12.fifo 13<$OUT/13.fifo 14<$OUT/14.fifo 15<$OUT/15.fifo 16<$OUT/16.fifo
}

function do_serial() {
    action=$1
    shift
    printf "Running ${action} (serially)   : "
    for target in $TEST_TARGETS; do
	if [ -x $S/${action}-exe-${target}.bash ]; then
	    $S/${action}-exe-${target}.bash "$@"
	fi
    done | progress i
}

for dir in core cast variants enums fsi32 fsi64 float range layout large; do
#    echo "---- $dir ------------------------"
    time do_parallel compile ../$dir/*.v3
#    time do_serial compile ../$dir/*.v3

    time do_parallel run ../$dir/*.v3
#    time do_serial run ../$dir/*.v3
done


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
