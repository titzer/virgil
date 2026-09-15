#!/bin/bash

. ../common.bash vmaddr

if [ $# -gt 0 ]; then
    TEST_LIST="$@"
else
    TEST_LIST=*.v3
fi


# All addresses must be 16KB-aligned (0x4000): arm64-linux uses 16KB pages, and an
# unaligned -vm-start-addr crashes the ELF writer (a checked cast overflows while
# computing segment offsets) since no real OS would ever load a segment at a
# non-page-aligned address in the first place.
#ADDRS_32="0x0000C000 0x000A0000 0x00300000 0x00910000 0x07000000 0x22220000 0x7FFF0000"
ADDRS_32="0x00300000 0x00910000 0x07000000 0x22220000 0x7FFF0000"
#ADDRS_48="0x100000000 0x200000000 0x333330000 0x4400044000 0x555500000000 0xFFFF12340000"
ADDRS_48="0x100000000 0x200000000 0x333330000 0x4400044000 0x555500000000"

# The heap is laid out at the end of the data segment, so a large heap pushes the
# highest address in the program image far past the 2GB and 4GB boundaries. The
# heap_*.v3 tests are run separately, once for each of these sizes; they scale
# themselves to the heap they are given. Large sizes only reserve virtual address
# space, since the tests touch just a few pages of it.
HEAP_SIZES_32=${HEAP_SIZES_32:="1m 1000m 1900m"}
# Wizard's JVM target caps a wasm memory at 30000 pages (1875MB), so stay below that.
HEAP_SIZES_WASM=${HEAP_SIZES_WASM:="1m 1000m 1800m"}
HEAP_SIZES_48=${HEAP_SIZES_48:="1m 3g 5g 12g 17000m"}
# Start addresses to combine with the heap sizes above.
HEAP_ADDRS_32=${HEAP_ADDRS_32:="0x00300000"}
HEAP_ADDRS_48=${HEAP_ADDRS_48:="0x00300000 0x100000000"}

HEAP_TEST_LIST=$(ls $TEST_LIST | grep '^heap_')
ADDR_TEST_LIST=$(ls $TEST_LIST | grep -v '^heap_')

PREV_V3C_OPTS="$V3C_OPTS"

# Vary the start address of the program image, with the default (small) heap.
for target in $TEST_TARGETS; do
    case "$(get_vm_addr_width $target)" in
	"32")
	    ADDRS="$ADDRS_32"
	    TESTS=$(echo $ADDR_TEST_LIST | tr ' ' '\n' | grep -v _64.v3)
	    ;;
	"48")
	    ADDRS="$ADDRS_32 $ADDRS_48"
	    TESTS="$ADDR_TEST_LIST"
	    ;;
	*)
	    continue
	    ;;
    esac

    if [ -z "$TESTS" ]; then continue; fi

    for addr in $ADDRS; do
	V3C_OPTS="$PREV_V3C_OPTS -vm-start-addr=$addr"
	compile_target_tests $target || exit $?
	execute_target_tests $target || exit $?
    done
done

# Vary the heap size, at a couple of different start addresses.
for target in $TEST_TARGETS; do
    case "$(get_vm_addr_width $target)" in
	"32")
	    if [ "$target" = wasm ]; then
		HEAPS="$HEAP_SIZES_WASM"
	    else
		HEAPS="$HEAP_SIZES_32"
	    fi
	    ADDRS="$HEAP_ADDRS_32"
	    TESTS=$(echo $HEAP_TEST_LIST | tr ' ' '\n' | grep -v _64.v3)
	    ;;
	"48")
	    HEAPS="$HEAP_SIZES_48"
	    ADDRS="$HEAP_ADDRS_48"
	    TESTS="$HEAP_TEST_LIST"
	    ;;
	*)
	    continue
	    ;;
    esac

    if [ -z "$TESTS" ]; then continue; fi

    for addr in $ADDRS; do
	for heap in $HEAPS; do
	    V3C_OPTS="$PREV_V3C_OPTS -vm-start-addr=$addr -heap-size=$heap"
	    compile_target_tests $target || exit $?
	    execute_target_tests $target || exit $?
	done
    done
done
