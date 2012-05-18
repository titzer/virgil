#/bin/bash

. ../common.bash gc

target=$TEST_TARGET
# TODO: run GC tests on all native platforms
if [ "$target" == x86-darwin ]; then 
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/darwin/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
elif [ "$target" == x86-linux ]; then
    RT_SOURCES="$VIRGIL_LOC/rt/native/*.v3 $VIRGIL_LOC/rt/linux/*.v3 $VIRGIL_LOC/rt/gc/*.v3"
else
    echo "  GC tests not supported for $target"
    exit 0
fi

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS=$(egrep '\[|[.]new' ../execute/*.v3 ../large/*.v3 | cut -d: -f1 | uniq)
fi

T=$OUT/$target
mkdir -p $T

AENEAS_FAST=$T/Aeneas

printf "  Compiling ($target) Aeneas..."
run_v3c "$target" -output=$T -heap-size=500m $AENEAS_SOURCES > $T/Aeneas.compile
check_no_red $? $T/Aeneas.compile

C=$T/$target-test.compile.out
rm -f $C

printf "  Compiling ($target) gc tests..."
for f in $TESTS; do
  # TODO: compile multiple tests at once with aeneas (no need for Aeneas-fast)
  $AENEAS_FAST -output=$T -target=$target-test -rt.gc -rt.gctables -rt.test-gc -rt.sttables -heap-size=10k $f $RT_SOURCES >> $C
done

check_no_red $? $C

run_native gc $target $TESTS

HEAP='-heap-size=24m'
printf "  Compiling ($target $HEAP) Aeneas..."
run_v3c $target -output=$T $HEAP $AENEAS_SOURCES &> $T/Aeneas-gc.compile.out
check_no_red $? $T/Aeneas-gc.compile.out
mv $T/Aeneas $T/Aeneas-gc

printf "  Testing   ($target $HEAP) Aeneas..."
$T/Aeneas-gc -test -rma $VIRGIL_LOC/test/execute/*.v3 &> $T/Aeneas-gc.test.out
check_red $T/Aeneas-gc.test.out
