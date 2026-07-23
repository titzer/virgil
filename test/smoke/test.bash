#!/usr/bin/env bash

. ../common.bash smoke

if [ $# -gt 0 ]; then
	ALL="$@"
else
	ALL=$(echo *.v3)
fi

# A test may carry extra compiler flags in a sibling <test>.v3.flags file, which
# lets this suite cover language features that are still behind a flag (e.g.
# -lang:descriptors). Tests are grouped by their exact flag string so that each
# distinct set is compiled and run once, rather than once per test.
function flags_of() {
	if [ -f "$1.flags" ]; then
		tr '\n' ' ' < "$1.flags" | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
	fi
}

# NOTE: do not name this variable GROUPS; that is a reserved bash variable
# holding the current user's group ids, and assigning to it silently has no
# effect, which would send this list to a file named after a group id instead.
FLAG_GROUPS=$OUT/flag-groups.txt
for t in $ALL; do
	flags_of "$t"
	echo
done | sort -u > $FLAG_GROUPS

BASE_OPTS="$V3C_OPTS"
while IFS= read -r g; do
	TESTS=""
	for t in $ALL; do
		if [ "$(flags_of "$t")" = "$g" ]; then
			TESTS="$TESTS $t"
		fi
	done
	if [ -z "$TESTS" ]; then
		continue
	fi
	if [ -n "$g" ]; then
		print_line
		echo "${CYAN}flags:${NORM} $g"
	fi
	V3C_OPTS="$BASE_OPTS $g"
	execute_tests
	V3C_OPTS="$BASE_OPTS"
done < $FLAG_GROUPS

exit $?
