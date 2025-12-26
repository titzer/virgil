#!/usr/bin/env bash

. ../common.bash core/link

if [ $# -gt 0 ]; then
	TESTS="$@"
else
	TESTS=*.v3
fi
VERBOSE="${VERBOSE:=0}"

# copied from gc/test.bash
function set_rt_files() {
	target=$1
	N="$RT_LOC/native/"
	GC_SOURCES="${GC_LOC}/*.v3"

	if [ "$target" = "x86-darwin" ]; then
		export RT_FILES="$RT_LOC/x86-darwin/*.v3 $N/*.v3 $GC_SOURCES"
	elif [ "$target" = "x86-64-darwin" ]; then
		export RT_FILES="$RT_LOC/x86-64-darwin/*.v3 $N/*.v3 $GC_SOURCES"
	elif [ "$target" = "x86-linux" ]; then
		export RT_FILES="$RT_LOC/x86-linux/*.v3 $N/*.v3 $GC_SOURCES"
	elif [ "$target" = "x86-64-linux" ]; then
		export RT_FILES="$RT_LOC/x86-64-linux/*.v3 $N/*.v3 $GC_SOURCES"
	elif [ "$target" = "wasm" ]; then
		export RT_FILES="./EmptySystem.v3 $N/NativeGlobalsScanner.v3 $N/NativeFileStream.v3 $GC_SOURCES"
	fi
}

function compile_target_tests() {
	target=$1
	print_compiling $target
	mkdir -p $OUT/$target
	C=$OUT/$target/compile.out
	V3C_OPTSX="$V3C_OPTS -target=$target-test -output=$OUT/$target"
	set_rt_files $target
	local F=$VIRGIL_LOC/bin/dev/v3c-$target
	if [ ! -x $F ]; then
		F=$VIRGIL_LOC/bin/v3c-$target
	fi
	rm -f $C
	LIB_LOC=$VIRGIL_LOC/lib/util
	for t in $TESTS; do
		if [ -z "${t##*_lib.v3}" ]; then
			# requires library files (and run time)
			RT_OPT="-rt.files=$(echo $RT_FILES $LIB_LOC/*.v3)"
			GC_OPT="-rt.gc -rt.gctables -rt.test-gc -rt.sttables -heap-size=10k"
		else
			RT_OPT=""
			GC_OPT=""
#			RT_OPT="-rt.files=$(echo $RT_FILES $LIB_LOC/*.v3)"
#			GC_OPT="-rt.gc -rt.gctables -rt.test-gc -rt.sttables -heap-size=10k"
		fi
		echo "Command: V3C=$AENEAS_TEST $F $V3C_OPTSX -multiple ${RT_OPT:+"$RT_OPT"} $GC_OPT $t"
		V3C=$AENEAS_TEST $F $V3C_OPTSX -multiple ${RT_OPT:+"$RT_OPT"} $GC_OPT $t
	done | tee $C | $PROGRESS
}

function check_target_tests() {
	target=$1
	print_status "Checking syms" $target
	mkdir -p $OUT/$target
	C=$OUT/$target/check.out
	rm -f $C
	for t in $TESTS; do
		obj=$OUT/$target/"${t/.v3/.o}"
		defineds="$(grep "^//@defined " $t)"
		echo "##>1" # for progress
		echo "##+$t" # for progress
		fail=0
		if [ -n "$defineds" ]; then
			defineds="${defineds#//@defined }"
			required="${defineds%%;*}"
			undefs="${defineds#$required}"
			undefs="${undefs#;}"
			while [ $fail = 0 ] && [ -n "${required}" ]; do
				require="${required%%,*}"
				required="${required#$require}"
				required="${required#,}"
				require="${require# }"
				reqgot="$(nm $obj | grep -e "$require\$")"
				if [ -z "$reqgot" ]; then
					echo "##-fail: Required symbol \"$require\" not found" # for progress
					fail=1
				fi
			done
			while [ $fail = 0 ] && [ -n "$undefs" ]; do
				undef="${undefs%%,*}"
				undefs="${undefs#$undef}"
				undefs="${undefs#,}"
				undef="${undef# }"
				undefgot="$(nm $obj | grep -e " $undef\$")"
				if [ -n "$undefgot" ]; then
					echo "##-fail: Unexpected symbol \"$undef\" appears" # for progress
					fail=1
				fi
			done
		fi
		if [ $fail = 0 ]; then
			echo "##-ok" # for progress
		fi
	done | tee $C | $PROGRESS
}

function compile_target_c_files() {
	target=$1
	print_status "C files" $target
	mkdir -p $OUT/$target
	C=$OUT/$target/cfiles.out
	rm -f $C
	MODEL=""
	if [ "$target" = "x86-linux" ]; then
		MODEL=-m32
	elif [ "$target" = "x86-64-linux" ]; then
		MODEL=-m64
	fi
	if [ -z "$MODEL" ]; then continue; fi
	export CC=${CC:=cc}
	for t in $TESTS; do
		cfile="${t/.v3/_.c}"
		if [ -r "$cfile" ]; then
			echo "##>1"  # for progress
			echo "##+$t" # for progress
			if $CC $MODEL -c "$cfile" -o $OUT/$target/"${cfile/.c/.o}"; then
				echo "##-ok" # for progress
			else
				echo "##-fail"
			fi
		fi
	done | tee $C | $PROGRESS
}

function link_target_tests() {
	target=$1
	print_status Linking $target
	mkdir -p $OUT/$target
	C=$OUT/$target/linking.out
	rm -f $C
	MODEL=""
	if [ "$target" = "x86-linux" ]; then
		MODEL=-m32
	elif [ "$target" = "x86-64-linux" ]; then
		MODEL=-m64
	fi
	if [ -z "$MODEL" ]; then continue; fi
	export CC=${CC:=cc}
	LD_SCRIPT="${LD_SCRIPT:=virgil-ld-script}"
	for t in $TESTS; do
		obj=$OUT/$target/"${t/.v3/.o}"
		if [ ! -r "$obj" ]; then continue; fi
			cfile="${t/.v3/_.c}"
			cobj=""
		if [ -r "$cfile" ]; then
			cobj=$OUT/$target/"${cfile/.c/.o}"
			if [ ! -r "$cobj" ]; then continue; fi
		fi
		echo "##>1"  # for progress
		echo "##+$t" # for progress
		if $CC $MODEL -no-pie -z noexecstack -T $LD_SCRIPT "$obj" ${cobj:+"$cobj"} -o $OUT/$target/"${t/.v3/}"; then
			echo "##-ok" # for progress
		else
			echo "##-fail"
		fi
	done | tee $C | $PROGRESS
}

function execute_target_tests() {
	target=$1
	mkdir -p $OUT/$target
	C=$OUT/$target/run.out
	rm -f $C
        TO_RUN=""
	TO_EXEC=""
	for t in $TESTS; do
		# note: suppress execute if run is present
		if grep -q "^//@run" $t; then TO_RUN+=" $t";
		elif grep -q "^//@execute" $t; then TO_EXEC+=" $t";
		fi
	done
	if [ -n "$TO_EXEC" ]; then
		local F=$VIRGIL_LOC/bin/dev/v3c-$target
		if [ ! -x $F ]; then
			F=$VIRGIL_LOC/bin/v3c-$target
		fi
		print_status Executing $target
		for t in $TO_EXEC; do
			V3C=$AENEAS_TEST $F -test -target=$target-test -output=$OUT/$target $t
		done | tee $OUT/$target/execute.out | $PROGRESS
	fi

	TO_RUN=""
	for t in $TESTS; do
		if grep -q "^//@run" $t; then TO_RUN+=" $t"; fi
	done
	if [ -n "$TO_RUN" ]; then
		print_status Running "$target"
		for tt in $TO_RUN; do
			echo "##>1"   # for progress
			echo "##+$tt" # for progress
			exe=$OUT/$target/"${tt/.v3/}"
			runcount=0
			runs="$(grep "^//@run " $tt)"
			runs="${runs#//@run }"
			fail=0
			while [ -n "$runs" ]; do
				arun="${runs%%;*}"
				runs="${runs#$arun}"
				runs="${runs#;}"
				runargs="${arun%%=*}"
				runargs="${runargs# }"
				runexpect="${arun##*=}"
				rungot="$($exe $runargs)"
				if [ "-x$rungot" != "-x$runexpect" ]; then
					echo "##-fail: Run $runcount expected $runexpect but got $rungot"
					fail=1
					break
				fi
				runcount=$(($runcount+1))
			done
			if [ "$fail" = 0 ]; then echo "##-ok"; fi
		done | tee $OUT/$target/run.out | $PROGRESS
	fi
}

for target in $TEST_TARGETS; do
	if [ "$target" = "x86-64-linux" ]; then
		(compile_target_tests $target) || exit $?
		(check_target_tests $target) || exit $?
		(compile_target_c_files $target) || exit $?
		(link_target_tests $target) || exit $?
		(execute_target_tests $target) || exit $?
	fi
done
