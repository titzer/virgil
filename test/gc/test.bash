#/bin/bash

. ../common.bash gc

target=$TEST_TARGET
# TODO: run GC tests on all native platforms
if [ "$target" == x86-darwin ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/darwin/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
elif [ "$target" == x86-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/linux/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
else
    echo "  GC tests not supported for TEST_TARGET=$target"
    exit 0
fi

if [ "$RUN_NATIVE" == 0 ]; then
    echo "  GC tests disabled by RUN_NATIVE environment variable"
    exit 0
fi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(cat execute.gc variants.gc large.gc)
fi

T=$OUT/$target
mkdir -p $T

C=$T/compile.out
ALL=$T/compile.all.out
rm -f $ALL

# TODO: compile all the tests in one invocation of the compiler
print_compiling "$target" "gc tests"
for f in $TESTS; do
  run_v3c "" -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -set-exec=false -heap-size=10k $f $RT_SOURCES > $C
  grep '31m' $C > $C.error
  if [ $? == 0 ]; then
	printf "${RED}failed${NORM}\n"
	cat $C.error
	exit 1
  fi
  cat $C >> $ALL
done

printf "${GREEN}ok${NORM}\n"

run_native $target

HEAP='-heap-size=24m'
print_compiling "$target $HEAP" Aeneas
run_v3c $target -output=$T $HEAP $AENEAS_SOURCES &> $T/Aeneas-gc.compile.out
check_no_red $? $T/Aeneas-gc.compile.out
mv $T/Aeneas $T/Aeneas-gc

print_status Testing "$target $HEAP" Aeneas
$T/Aeneas-gc -test -rma $VIRGIL_LOC/test/execute/*.v3 &> $T/Aeneas-gc.test.out
check_red $T/Aeneas-gc.test.out
