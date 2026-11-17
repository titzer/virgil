#!/usr/bin/env bash
# Multi-file extension tests. Each subdirectory is one test program: all .v3 files
# in it are compiled together and run through v3i. The test's expected //@execute
# annotation is read from any file in the directory.

. ../common.bash ext_multifile

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=$(ls -d */ 2>/dev/null | sed 's|/$||')
fi

mkdir -p $OUT

run_one_target() {
	local label="$1"
	local v3c_extra="$2"

	print_status Running "v3i $v3c_extra"
	local count=0
	for t in $TESTS; do
		if [ -d "$t" ]; then count=$((count+1)); fi
	done
	local out=$OUT/$label.out

	(
		echo "##>$count"
		for t in $TESTS; do
			if [ ! -d "$t" ]; then continue; fi
			echo "##+$t"
			local files
			files=$(ls "$t"/*.v3 2>/dev/null)
			if [ -z "$files" ]; then
				echo "##-fail: no .v3 files in $t"
				continue
			fi
			local annot
			annot=$(grep -h "^//@execute " $files 2>/dev/null | head -1)
			annot="${annot#//@execute }"
			if [ -z "$annot" ]; then
				echo "##-fail: no //@execute annotation in $t"
				continue
			fi
			local failed=0 fail_msg=""
			local IFS_OLD="$IFS"
			IFS=';'
			for pair in $annot; do
				IFS="$IFS_OLD"
				pair="${pair# }"
				pair="${pair// /}"
				local input="${pair%%=*}"
				local expected="${pair##*=}"
				local got
				got=$($AENEAS_TEST $V3C_OPTS $v3c_extra -run $files "$input" 2>&1)
				local rc=$?
				# -run returns the int via exit code (mod 256).
				if [ "$rc" != "$expected" ]; then
					failed=1
					fail_msg="input=$input expected=$expected got=$rc out=[$got]"
					break
				fi
				IFS=';'
			done
			IFS="$IFS_OLD"
			if [ "$failed" = 0 ]; then
				echo "##-ok"
			else
				echo "##-fail: $fail_msg"
			fi
		done
	) | tee $out | $PROGRESS
}

run_one_target "v3i" ""
run_one_target "v3i-ra" "-ra -ma=false"
run_one_target "v3i-ra-ma" "-ra -ma=true"
