#!/usr/bin/env bash


VIRGIL_LOC=${VIRGIL_LOC:=$(cd $(dirname ${BASH_SOURCE[0]}) && cd ../../ && pwd)}

if (( $# != 1 )); then
	echo "No test type specified"
	exit -1
fi

TEST_TYPE=$1
TEST_DIR=$VIRGIL_LOC/test/peval/$TEST_TYPE

if [ ! -d "$TEST_DIR" ]; then
	echo "Test type not found in virgil/test/peval"
	exit -1
fi


# Iterate over each file in the test directory
ALL_TESTS="$( ls "$TEST_DIR" )"

FAILED_TESTS="failed-peval-test-gen.txt"
rm -f "$TEST_DIR/$FAILED_TESTS"
touch "$TEST_DIR/$FAILED_TESTS"

ERR_FILE="/tmp/pe_err.txt"

CUR_DIR="$( pwd )"

cd $TEST_DIR
for cur_test in $ALL_TESTS; do
    OUTPUT=$(v3c-dev -test -ra $cur_test 2> $ERR_FILE)
    EXIT_STATUS=$?
    ERR=$(<$ERR_FILE)
    echo $OUTPUT
    EXN_PATT="Exception"
    ERR_PATT="Error"
    if [[ $ERR =~ $EXN_PATT ]]; then
        echo "Failed $cur_test"
        echo "$cur_test" >> $FAILED_TESTS
    elif [[ $ERR =~ $ERR_PATT ]]; then
        echo "Failed $cur_test"
        echo "$cur_test" >> $FAILED_TESTS
    elif (( $EXIT_STATUS == 1 )); then
        echo "$cur_test" >> $FAILED_TESTS
    fi
done


