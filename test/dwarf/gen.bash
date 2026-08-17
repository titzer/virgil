#!/usr/bin/env bash
# Regenerates the expected output of the gdb-driven dwarf tests from the current
# compiler. Review the diff before committing: this overwrites the goldens, so a
# regression will happily be recorded as the new expectation.
#
#   ./gen.bash              regenerate every *.static.out
#   ./gen.bash lines.v3     regenerate only the goldens for lines.v3
#
# The *.run.out files are deliberately not generated: they contain only "ok:"
# lines asserted by gdb conditionals, and are meant to be written by hand.

. ../common.bash dwarf

TARGET=x86-64-linux
T=$OUT/$TARGET

GDB=$(echo $CONFIG/gdb-$TARGET*)
if [ "$GDB" = "$CONFIG/gdb-$TARGET*" ] || [ ! -x "$GDB" ]; then
    echo "gen.bash: no gdb configured for $TARGET; run ../configure"
    exit 1
fi

./test.bash "$@" > /dev/null 2>&1

if [ $# -gt 0 ]; then
    SCRIPTS=""
    for t in $@; do SCRIPTS="$SCRIPTS $(basename $t .v3).static.gdb"; done
else
    SCRIPTS=$(ls *.static.gdb)
fi

for script in $SCRIPTS; do
    base=$(basename $script .static.gdb)
    if [ ! -f $T/$base.static.out ]; then
	echo "  $base.static.out ${RED}not produced${NORM}"
	continue
    fi
    cp $T/$base.static.out $base.static.out
    echo "  $base.static.out ${GREEN}updated${NORM}"
done
