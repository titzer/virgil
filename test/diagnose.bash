#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

. $DIR/common.bash diagnose

if [ $# != 2 ]; then
	echo "Usage: diagnose.bash <target> <one test>"
        exit 1
fi

target=$1
shift

T=$OUT/$target
mkdir -p $T

TESTS=$1
TESTS_NO_EXT=${1%*.*}

if [ ! -e "$1" ]; then
	echo "File not found: $1"
        exit 1
fi

print_line
echocute cat $TESTS

print_line
compile_target_tests $target "-fatal -print-ssa -print-mach -print-stackify -symbols"
cat $T/compile.out
print_line
echocute $DIR/config/test-$target $T $TESTS | tee $T/${TEST_NO_EXT}.run.out
echo gdb $T/${TEST_NO_EXT}
