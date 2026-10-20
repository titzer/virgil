#!/usr/bin/env bash

. ../common.bash buildopt

# Run each test with SSA builders optimizing instructions as they are added, in each
# compiler phase separately (one phase's folding can hide another's) and all together.
# At -O0, earlier passes leave more to fold during lowering, e.g. throws.
# At -O2, the normalized and machine code is optimized again after it is built.
BASE_OPTS="$V3C_OPTS"

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi

for level in "" "-O0" "-O2"; do
	for flags in VstBuildOpt NormBuildOpt MachBuildOpt VstBuildOpt,+NormBuildOpt,+MachBuildOpt; do
		V3C_OPTS="$BASE_OPTS $level -opt=+$flags"
		execute_tests
	done
done
