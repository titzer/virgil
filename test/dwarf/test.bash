#!/usr/bin/env bash

. ../common.bash dwarf

# The dwarf test suite checks the DWARF debug information emitted by "-dwarf".
# It runs in three tiers, each of which is skipped if its prerequisites are
# missing. See ./README for details.
#
#   compile  every program compiles with -dwarf
#   run      the binary still behaves identically with debug info in it
#   gdb      gdb reads the debug info (*.static.gdb) and steps through the
#            running program (*.run.gdb)

if [ $# -gt 0 ]; then
    TESTS="$@"
else
    TESTS=$(ls *.v3)
fi

# Rewrite gdb output into a form that is stable across machines and builds:
# addresses, build directories and gdb chatter all vary. Breakpoint banners and
# echoed source lines are dropped too, so that the *.run.gdb tests come down to
# the "ok:" lines their assertions print.
function normalize() {
    sed -e "s|$T/||g" \
	-e "s|$VIRGIL_LOC/||g" \
	-e 's/0x[0-9a-fA-F][0-9a-fA-F]*/0xADDR/g' \
	-e 's/+[0-9][0-9]*>/+N>/g' \
	-e '/^warning: /d' \
	-e '/^Reading symbols/d' \
	-e '/^\[Inferior /d' \
	-e '/^\[New /d' \
	-e '/^During startup/d' \
	-e '/^Breakpoint [0-9]* at /d' \
	-e '/^The target architecture is set to /d' \
	-e '/^Reading .* from remote target/d' \
	-e '/^0xADDR in ?? ()$/d' \
	-e '/^Breakpoint [0-9]*, /d' \
	-e '/^Continuing\./d' \
	-e '/^[0-9][0-9]*	/d' \
	-e '/^$/d' \
	"$1"
}

# Returns true if there is a v3c wrapper script for {target}; some native
# targets in TEST_TARGETS have a backend but no wrapper to drive it yet.
function have_v3c_for() {
    [ -x "$VIRGIL_LOC/bin/dev/v3c-$1" ] || [ -x "$VIRGIL_LOC/bin/v3c-$1" ]
}

function compile_tests() {
    trace_test_count $#
    for t in $@; do
	trace_test_start $t
	run_v3c $target -output=$T -dwarf $t &> $T/$(basename $t).compile.out
	trace_test_retval $? $T/$(basename $t).compile.out
    done
}

# Drive gdb with a script and diff its (normalized) output against the golden.
function run_gdb_tests() {
    local kind=$1
    shift
    trace_test_count $#
    for script in $@; do
	local base=$(basename $script .$kind.gdb)
	trace_test_start $script
	local P=$T/$base.$kind
	# copy the script next to the binary; the gdb runner may be sandboxed
	cp $script $P.gdb
	local runner=$GDB
	if [ "$kind" = run ]; then runner=$GDBRUN; fi
	$runner $T $T/$base $P.gdb > $P.raw 2>&1
	normalize $P.raw > $P.out
	diff $base.$kind.out $P.out > $P.diff
	if [ $? = 0 ]; then trace_test_ok; else trace_test_fail $P.diff; fi
    done
}

# Probe whether gdb can actually execute the compiled binaries. Emulated
# environments (e.g. linux/amd64 containers on Apple silicon) can read the
# debug info but cannot ptrace the inferior.
function gdb_can_run() {
    local probe=$1
    echo 'run' > $T/probe.gdb
    $GDBRUN $T $T/$probe $T/probe.gdb > $T/probe.out 2>&1
    grep -q 'exited normally' $T/probe.out
}

function run_gdb_tiers() {
    # The goldens record where each variable lives and which methods exist,
    # both of which are properties of a particular pipeline configuration: at
    # -O3 a method the golden names gets inlined away, and at -O0 a local lands
    # in a different stack slot. Compare them only at the default optimization
    # level. The compile and run tiers above still run under whatever flags the
    # ambient V3C_OPTS carries, so debug info is exercised across them.
    case " $V3C_OPTS " in
	*" -O"*)
	    print_status Gdb "$target"
	    echo "${YELLOW}skipped${NORM} (goldens are for the default optimization level)"
	    return 0
	    ;;
    esac
    GDB=$(echo $CONFIG/gdb-$target*)
    if [ "$GDB" = "$CONFIG/gdb-$target*" ] || [ ! -x "$GDB" ]; then
	print_status Gdb $target
	echo "${YELLOW}skipped${NORM} (no gdb configured for $target)"
	return 0
    fi
    # Reading the debug info and executing under the debugger are separate
    # capabilities; a host may have the first without the second.
    GDBRUN=$(echo $CONFIG/gdbrun-$target*)
    if [ "$GDBRUN" = "$CONFIG/gdbrun-$target*" ] || [ ! -x "$GDBRUN" ]; then
	GDBRUN=""
    fi

    local static_tests=$(ls *.static.gdb 2> /dev/null)
    if [ ! -z "$static_tests" ]; then
	print_status Gdb "$target static"
	run_gdb_tests static $static_tests | tee $T/gdb-static.out | $PROGRESS
	fail_fast
    fi

    local run_tests=$(ls *.run.gdb 2> /dev/null)
    if [ ! -z "$run_tests" ]; then
	print_status Gdb "$target run"
	if [ -z "$GDBRUN" ]; then
	    echo "${YELLOW}skipped${NORM} (no gdbrun runner for $target)"
	elif gdb_can_run $(basename $(echo $run_tests | cut -d' ' -f1) .run.gdb); then
	    run_gdb_tests run $run_tests | tee $T/gdb-run.out | $PROGRESS
	    fail_fast
	else
	    echo "${YELLOW}skipped${NORM} (gdb cannot execute $target binaries here)"
	fi
    fi
}

for target in $(get_io_targets); do
    T=$OUT/$target
    mkdir -p $T

    if [[ ! "$target" =~ ^v3i ]]; then
	if ! have_v3c_for $target; then
	    print_compiling $target
	    echo "${YELLOW}skipped${NORM} (no compiler script for $target)"
	    continue
	fi
	print_compiling $target
	compile_tests $TESTS | tee $T/compile.out | $PROGRESS
	fail_fast
    fi

    # Compiling with -dwarf must never change what the program does, whether or
    # not the target emits debug information.
    run_or_skip_io_tests $target $TESTS
    fail_fast

    # Only some backends emit DWARF; on the rest, -dwarf is silently ignored and
    # there is nothing for gdb to check.
    case $target in
	x86-64-linux)
	    run_gdb_tiers
	    ;;
	x86-linux | arm64-linux)
	    #TODO: emit DWARF from the x86 and arm64 Linux backends
	    ;;
	x86-darwin | x86-64-darwin | arm64-darwin)
	    #TODO: emit DWARF into Mach-O binaries
	    ;;
	v3i* | jar | wasm*)
	    # not a native target; the interpreter has its own debugger (test/debug)
	    # and the wasm targets carry their own debug info format
	    ;;
	*)
	    print_status Gdb $target
	    echo "${YELLOW}skipped${NORM} (unknown target)"
	    ;;
    esac
done
