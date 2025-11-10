#!/bin/bash

. ../common.bash vmaddr

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi


#ADDRS_32="0x0000E000 0x000A0000 0x00300000 0x00911000 0x07000000 0x22220000 0x7FFF0000"
ADDRS_32="0x00300000 0x00911000 0x07000000 0x22220000 0x7FFF0000"
#ADDRS_48="0x100000000 0x200000000 0x333330000 0x4400044000 0x555500000000 0xFFFF12340000"
ADDRS_48="0x100000000 0x200000000 0x333330000 0x4400044000 0x555500000000"

PREV_V3C_OPTS="$V3C_OPTS"

for target in $TEST_TARGETS; do
    case "$(get_vm_addr_width $target)" in
	"32")
	    ADDRS="$ADDRS_32"
	    ;;
	"48")
	    ADDRS="$ADDRS_32 $ADDRS_48"
	    ;;
	*)
	    continue
	    ;;
    esac

    for addr in $ADDRS; do
	V3C_OPTS="$PREV_V3C_OPTS -vm-start-addr=$addr"
	compile_target_tests $target || exit $?
	execute_target_tests $target || exit $?
    done
done
