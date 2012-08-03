#!/bin/bash

. ../common.bash stacktrace

compiled=0

target=$TEST_TARGET
T=$OUT/$target
mkdir -p $T

# TODO: reduce duplication between stacktrace and system
function do_test() {
	tests="$tests $1"
	params="$2"
	exp="$3"
	local expect=$OUT/$1.expect
	local out=$OUT/$1.out
	rm -f $out $expect
	if [ "$exp" = "" ]; then touch $expect
	else printf "$exp" > $expect
	fi
	if [ $compiled = 1 ]; then
		run_io_test $target "${1%*.*}" "$params" "$expect" 
	else
		printf "  Running   (int) %s..." $1
		run_v3c "" -run $1 $params > $out
		diff $expect $out > /dev/null
		check $?
	fi
}

function do_tests() {

do_test st_abstract00.v3 "" "!UnimplementedException
	in st_abstract00.main() [st_abstract00.v3 @ 2:13]\n\n"
do_test st_abstract01.v3 "" "!UnimplementedException
	in st_abstract01.abs() [st_abstract01.v3 @ 5:13]
	in st_abstract01.main() [st_abstract01.v3 @ 3:27]\n\n"
do_test st_null01.v3 "" "!NullCheckException
	in st_null01.main() [st_null01.v3 @ 4:25]\n\n"
do_test st_bound01.v3 "" "!BoundsCheckException
	in st_bound01.main() [st_bound01.v3 @ 3:25]\n\n"
do_test st_del01.v3 "a" "!DivideByZeroException
	in st_del01.del1() [st_del01.v3 @ 8:26]
	in st_del01.main() [st_del01.v3 @ 5:25]\n\n"
do_test st_del01.v3 "a a" "!DivideByZeroException
	in st_del01.del2() [st_del01.v3 @ 11:26]
	in st_del01.main() [st_del01.v3 @ 5:25]\n\n"
do_test st_del03.v3 "a" "!DivideByZeroException
	in st_del03.del1() [st_del03.v3 @ 8:26]
	in st_del03.main() [st_del03.v3 @ 5:25]\n\n"
do_test st_del03.v3 "a a" "!DivideByZeroException
	in st_del03.del2() [st_del03.v3 @ 11:26]
	in st_del03.main() [st_del03.v3 @ 5:25]\n\n"
do_test st_del02.v3 "a" "Hello"
do_test st_del02.v3 "" "!NullCheckException
	in st_del02.main() [st_del02.v3 @ 4:18]\n\n"
do_test st_deep00.v3 "" "!LengthCheckException
	in st_deep00.f() [st_deep00.v3 @ 13:56]
	in st_deep00.e() [st_deep00.v3 @ 11:20]
	in st_deep00.d() [st_deep00.v3 @ 10:20]
	in st_deep00.c() [st_deep00.v3 @ 9:20]
	in st_deep00.b() [st_deep00.v3 @ 8:20]
	in st_deep00.a() [st_deep00.v3 @ 7:20]
	in st_deep00.main() [st_deep00.v3 @ 5:18]\n\n"
do_test st_deep00.v3 "a" "!BoundsCheckException
	in st_deep00.f() [st_deep00.v3 @ 14:61]
	in st_deep00.e() [st_deep00.v3 @ 11:20]
	in st_deep00.d() [st_deep00.v3 @ 10:20]
	in st_deep00.c() [st_deep00.v3 @ 9:20]
	in st_deep00.b() [st_deep00.v3 @ 8:20]
	in st_deep00.a() [st_deep00.v3 @ 7:20]
	in st_deep00.main() [st_deep00.v3 @ 5:18]\n\n"
do_test st_deep00.v3 "a b" "!NullCheckException
	in st_deep00.f() [st_deep00.v3 @ 15:58]
	in st_deep00.e() [st_deep00.v3 @ 11:20]
	in st_deep00.d() [st_deep00.v3 @ 10:20]
	in st_deep00.c() [st_deep00.v3 @ 9:20]
	in st_deep00.b() [st_deep00.v3 @ 8:20]
	in st_deep00.a() [st_deep00.v3 @ 7:20]
	in st_deep00.main() [st_deep00.v3 @ 5:18]\n\n"
}

compiled=0
do_tests

target=$TEST_TARGET
if [[ "$target" != x86-darwin && "$target" != x86-linux ]]; then
    echo "  Skipping  ($target/$HOST_PLATFORM)...${YELLOW}ok${NORM}"
    exit 0
fi

AENEAS_RT="$VIRGIL_LOC/rt/darwin/*.v3 $VIRGIL_LOC/rt/native/*.v3"

tests=$(ls *.v3)

for t in $tests; do
  printf "  Compiling ($target) $t..."
  run_v3c $target -output=$T $t &> $T/$t.compile.out
  check_no_red $? $T/$t.compile.out
done

compiled=1
do_tests

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(ls ../execute/*.v3)
fi

AENEAS_FAST=$T/Aeneas

C=$T/$target-test.compile.out
rm -f $C

if [ "$target" == x86-darwin ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/darwin/*.v3"
elif [ "$target" == x86-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/linux/*.v3"
else
    echo "  Stacktrace tests not supported for $target"
    exit 0
fi

printf "  Compiling ($target) Aeneas..."
run_v3c "$target" -output=$T -heap-size=500m $AENEAS_SOURCES > $T/Aeneas.compile
check_no_red $? $T/Aeneas.compile

rm -f $T/*.st
printf "  Gathering stack traces (int)..."
run_v3c "" -test -test.st -output=$T $TESTS $> $T/test
check_red $T/test

printf "  Compiling ($target)..."
ST_TESTS=$(ls $T/*.st)
for f in $ST_TESTS; do
  # TODO: compile multiple tests at once with aeneas (no need for Aeneas-fast)
  fname="../execute/$(basename $f)"
  fname="${fname%*.*}.v3"
  $AENEAS_FAST -output=$T -target=$target-test -rt.sttables $fname $RT_SOURCES >> $C
done
check_no_red $? $C

run_native stacktrace $target $ST_TESTS
