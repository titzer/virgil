#!/bin/bash
. funcs.bash
if [ $# = 0 ]; then
	echo "Usage: compile.bash <target> [benchmarks]"
	exit 1
fi

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC=${VIRGIL_LOC:=$(cd $DIR/.. && pwd)}

cd $DIR

BTIME="./btime-$(../bin/dev/sense_host | cut -d' ' -f1)"

TMP=/tmp/$USER/virgil-bench/
mkdir -p $TMP

if [ -x $1 ]; then
	binary=$1
	shift
	TMP=$TMP/$1
	mkdir -p $TMP
	shift
fi

target="$1"
shift

if [ $# = 0 ]; then
	benchmarks=$(./list-benchmarks.bash)
else
	benchmarks="$*"
	shift
fi

function do_compile() {
    p=$1
    opts="${V3C_OPTS[@]}"
    PROG=$p-$target
    EXE=$TMP/$PROG

    files="Common.v3 $p/*.v3"
    if [ -x "$p/$p.bash" ]; then
	files=$($p/$p.bash $TMP)
    fi
    if [ -f "$p/v3c-opts" ]; then
	opts="$opts $(cat $p/v3c-opts)"
    fi
    if [ -f "$p/v3c-opts-$target" ]; then
	opts="$opts $(cat $p/v3c-opts-$target)"
    fi

		if [ ! -z $binary ]; then
			# compile with provided binary
			RT=$VIRGIL_LOC/rt
			RT_FILES=$(echo $RT/$target/*.v3 $RT/native/*.v3 $RT/gc/*.v3)
			CONFIG="-heap-size=200m -stack-size=2m -target=$target -rt.sttables -rt.gc -rt.gctables -rt.files="
			$BTIME -i 1 $binary $CONFIG"$RT_FILES" -output=$TMP -program-name=$PROG "${opts[@]}" $files
			return $?
    elif [ "$target" = "v3i" ]; then
	# v3i is a special target that runs the V3C interpreter
	echo "#!/bin/bash" > $EXE
	echo "exec v3i $files \"$@\"" >> $EXE
	chmod 755 $EXE
	return 0
    elif [ "$target" = "v3i-ra" ]; then
	# v3i is a special target that runs the V3C interpreter (with -ra)
	echo "#!/bin/bash" > $EXE
	echo "exec v3i -ra $files \"$@\"" >> $EXE
	chmod 755 $EXE
	return 0
    else
	# compile to the given target architecture
	v3c-$target -output=$TMP -program-name=$PROG "${opts[@]}" $files
	return $?
    fi
}

for p in $benchmarks; do
	if [ -z $binary ]; then
		printf "##+compiling (%s) %s\n" $target $p
	else
		printf "##+compiling %s (%s) %s\n" $binary $target $p
	fi
	do_compile $p

	if [ $? != 0 ]; then
	    printf "##-fail\n"
	else
	    printf "##-ok\n"
	fi
done
