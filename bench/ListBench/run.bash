#!/bin/bash

TMP=/tmp/ListBench

mkdir -p /tmp/ListBench
rm -f /tmp/ListBench/*

JAVA=$(which java)

echo "Compiling btime..."
gcc -O2 -o $TMP/btime ../btime.c

echo "Compiling (java) ListBench..."
javac -d $TMP ListBench.java

echo "Compiling (jar -server) ListBench..."
v3c-jar -output=$TMP/ -jvm.args='-server' ../Common.v3 ListBench.v3 && mv $TMP/ListBench $TMP/ListBench-jar-server

echo "Compiling (jar -client) ListBench..."
v3c-jar -output=$TMP/ -jvm.args='-d32 -client' ../Common.v3 ListBench.v3 && mv $TMP/ListBench $TMP/ListBench-jar-client

echo "Compiling (x86-darwin) ListBench..."
v3c-x86-darwin -output=$TMP/ ../Common.v3 ListBench.v3 && mv $TMP/ListBench $TMP/ListBench-x86-darwin

RUNS=10

function run_bench() {
	echo "Running: $1 $2"
	$TMP/btime $1.out $RUNS $1 $2
}

function run_java() {
	echo "Running: java -cp $TMP $1 ListBench $2"
	$TMP/btime "$TMP/java$1.out" $RUNS $JAVA -cp $TMP $1 ListBench $2
}

ITERS=100000

echo
run_bench $TMP/ListBench-x86-darwin "$ITERS 1 1"
run_bench $TMP/ListBench-x86-darwin "1 $ITERS 1"
run_bench $TMP/ListBench-x86-darwin "1 1 $ITERS"

echo
run_bench $TMP/ListBench-jar-client "$ITERS 1 1"
run_bench $TMP/ListBench-jar-client "1 $ITERS 1"
run_bench $TMP/ListBench-jar-client "1 1 $ITERS"

echo
run_java "-d32 -client" "$ITERS 1 1"
run_java "-d32 -client" "1 $ITERS 1"
run_java "-d32 -client" "1 1 $ITERS"

echo
run_bench $TMP/ListBench-jar-server "$ITERS 1 1"
run_bench $TMP/ListBench-jar-server "1 $ITERS 1"
run_bench $TMP/ListBench-jar-server "1 1 $ITERS"

echo
run_java "-server" "$ITERS 1 1"
run_java "-server" "1 $ITERS 1"
run_java "-server" "1 1 $ITERS"

