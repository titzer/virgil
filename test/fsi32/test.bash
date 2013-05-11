#!/bin/bash

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
../testexec.bash fsi32 $TESTS
exit $?
