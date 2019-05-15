#!/bin/bash

S=$1
O=$1.out
L=$1.list

rm -f $O
nasm -l $L $S

perl -n -e'/; var (.*)/ && print "var $1\n"' $L >> $O
perl -n -e'/ \d+ [0-9A-F]+ ([0-9A-F]+)\(?([0-9A-F]*)\)? .*; (.*)/ && print "x($3,\"$1$2\");\n"' $L >> $O

cat $O
