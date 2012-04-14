#!/bin/bash

TMP=/tmp/HashBench

mkdir -p /tmp/HashBench
rm -f /tmp/HashBench/*

JAVA=$(which java)

echo "Compiling btime..."
gcc -O2 -o $TMP/btime ../btime.c

echo "Compiling (java) HashBench..."
javac -d $TMP HashBench.java

echo "Compiling (jar -server) HashBench..."
v3c-jar -output=$TMP/ -jvm.args='-server' ../Common.v3 HashBench.v3 && mv $TMP/HashBench $TMP/HashBench-jar-server

echo "Compiling (jar -client) HashBench..."
v3c-jar -output=$TMP/ -jvm.args='-d32 -client' ../Common.v3 HashBench.v3 && mv $TMP/HashBench $TMP/HashBench-jar-client

echo "Compiling (x86-darwin) HashBench..."
v3c-x86-darwin -output=$TMP/ ../Common.v3 HashBench.v3 && mv $TMP/HashBench $TMP/HashBench-x86-darwin

RUNS=10

function run_bench() {
	echo "Running: $1 $2"
	$TMP/btime $1.out $RUNS $1 $2
}

function run_java() {
	echo "Running: java -cp $TMP $1 HashBench $2"
	$TMP/btime "$TMP/java$1.out" $RUNS $JAVA -cp $TMP $1 HashBench $2
}

ITERS=2000000

echo
run_bench $TMP/HashBench-x86-darwin "$ITERS 1 1 1"
run_bench $TMP/HashBench-x86-darwin "1 $ITERS 1 1"
run_bench $TMP/HashBench-x86-darwin "1 1 $ITERS 1"
run_bench $TMP/HashBench-x86-darwin "1 1 1 $ITERS"

echo
run_bench $TMP/HashBench-jar-client "$ITERS 1 1 1"
run_bench $TMP/HashBench-jar-client "1 $ITERS 1 1"
run_bench $TMP/HashBench-jar-client "1 1 $ITERS 1"
run_bench $TMP/HashBench-jar-client "1 1 1 $ITERS"

echo
run_java "-d32 -client" "$ITERS 1 1 1"
run_java "-d32 -client" "1 $ITERS 1 1"
run_java "-d32 -client" "1 1 $ITERS 1"
run_java "-d32 -client" "1 1 1 $ITERS"

echo
run_bench $TMP/HashBench-jar-server "$ITERS 1 1 1"
run_bench $TMP/HashBench-jar-server "1 $ITERS 1 1"
run_bench $TMP/HashBench-jar-server "1 1 $ITERS 1"
run_bench $TMP/HashBench-jar-server "1 1 1 $ITERS"

echo
run_java "-server" "$ITERS 1 1 1"
run_java "-server" "1 $ITERS 1 1"
run_java "-server" "1 1 $ITERS 1"
run_java "-server" "1 1 1 $ITERS"

