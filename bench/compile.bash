#!/bin/bash

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

TMP=/tmp/$USER/virgil-bench/
mkdir -p $TMP

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

    if [ "$target" = "v3i" ]; then
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
	printf "##+compiling (%s) %s\n" $target $p

	do_compile $p

	if [ $? != 0 ]; then
	    printf "##-fail\n"
	else
	    printf "##-ok\n"
	fi
done
