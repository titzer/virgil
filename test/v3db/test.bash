#!/usr/bin/env bash

. ../common.bash v3db

if [ $# -gt 0 ]; then
  TESTS="$*"
else
  TESTS="$(ls *.v3)"
fi

# At -O3, early inlining copies small callees into their callers, where breakpoints
# set in a callee never fire and frames differ, so these transcripts do not apply.
case " $V3C_OPTS " in
    *" -O3 "*)
	TESTS=$(for t in $TESTS; do grep -qx "$t" O3.skip || echo $t; done)
	;;
esac

target=v3db

T=$OUT/$target
mkdir -p $T

run_or_skip_io_tests $target $TESTS
