#!/bin/bash
HERE=$(command dirname ${BASH_SOURCE[0]})
. $HERE/funcs.bash
BS=$(cd $HERE && pwd)
VIRGIL=$(cd $BS/../../ && pwd)

TMP=$1
BSTMP=$1/bootstrap

if [ -d $TMP ]; then
	mkdir -p $BSTMP
else
	echo "Usage: bootstrap <TMP>"
	exit 1
fi

cp $VIRGIL/rt/jvm/bin/* $BSTMP
cat $VIRGIL/aeneas/src/*/*.v3 > $BSTMP/Aeneas.v3

echo "-target=jar -output=$BSTMP -jvm.rt-path=$BSTMP $BSTMP/Aeneas.v3" > $BS/args-large
echo $BSTMP/Aeneas.v3
