#!/usr/bin/env bash


VIRGIL_LOC=${VIRGIL_LOC:=$(cd $(dirname ${BASH_SOURCE[0]}) && cd ../../ && pwd)}

if (( $# != 1 )); then
	echo "No test type specified"
	exit -1
fi

TEST_TYPE=$1
TEST_DIR=$VIRGIL_LOC/test/$TEST_TYPE
PEVAL_TEST_DIR=$VIRGIL_LOC/test/peval/$TEST_TYPE

if [ ! -d "$TEST_DIR" ]; then
	echo "Test type not found in virgil/test/"
	exit -1
fi


# Iterate over each file in the test directory
ALL_TESTS="$( ls "$TEST_DIR" )"

if [ ! -d "$PEVAL_TEST_DIR" ]; then 
	echo "Partial eval test suite doesn't exist. Creating $PEVAL_TEST_DIR"
	mkdir -p $PEVAL_TEST_DIR
fi

FAILED_TESTS=$VIRGIL_LOC/test/peval/failed-peval-test-gen.txt
rm -f "$(pwd)" "$FAILED_TESTS"
touch "$FAILED_TESTS"

cd $PEVAL_TEST_DIR
for cur_test in $ALL_TESTS; do
	echo "Generating test: $cur_test"
	v3c-dev -test.pe -test "$TEST_DIR/$cur_test"

	echo "Finished generating $cur_test"

done


