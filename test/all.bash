#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

EXIT_SUCCESS=0

#######################################################################
# Sense stable compiler and host platform, or use environment variables
#######################################################################

HOSTS=$($DIR/../bin/dev/sense_host)
if [ "$?" != 0 ]; then
    echo $HOSTS
    exit 1
fi

if [ "$V3C_STABLE" = "" ]; then
    for h in $HOSTS; do
	STABLE_DIR=$(cd $DIR/../bin/stable/ && pwd)/$h
	V3C_STABLE=$STABLE_DIR/Aeneas
	if [ -x $V3C_STABLE ]; then
	    break
	fi
    done
fi

if [ ! -x "$V3C_STABLE" ]; then
    echo "Error: No stable compiler found."
    if [ ! -d "$STABLE_DIR" ]; then
	echo "  STABLE_DIR=\"$STABLE_DIR\" does not exist."
	exit 1
    fi
    echo "  STABLE_DIR=\"$STABLE_DIR\" does not contain a valid compiler."
    exit 1
fi

if [ "$TEST_HOST" == "" ]; then
    for h in $HOSTS; do
	V3C_TO_HOST=$(cd $DIR/../bin/ && pwd)/v3c-$h
	if [ -x $V3C_TO_HOST ]; then
	    TEST_HOST=$h
	    break
	fi
    done
fi

V3C_TO_HOST=$(cd $DIR/../bin/ && pwd)/v3c-$TEST_HOST

if [ ! -x "$V3C_TO_HOST" ]; then
    echo "Error: No compiler to host platform found."
    echo "  \"$V3C_TO_HOST\" is not contain a valid script."
    exit 1
fi

if [ ! -d "$TEST_CACHE" ]; then
    if [ -d "$VIRGIL_LOC/test/cache" ]; then
	export TEST_CACHE=$VIRGIL_LOC/test/cache
    fi
fi

# "auto" means recompile from stable
if [ -z "$AENEAS_TEST" ]; then
    AENEAS_TEST=auto
else
    BOOTSTRAP=$AENEAS_TEST
fi

#######################################################################
# Init test framework
#######################################################################
# Clean up results of any previous tests
rm -rf /tmp/$USER/virgil-test

. $DIR/common.bash all

# Echo all configurable variables
if [ "$QUIET_SETUP" != 1 ]; then
    echo "TEST_HOST=$TEST_HOST"
    echo "TEST_TARGETS=\"$TEST_TARGETS\""
    echo "TEST_CACHE=$TEST_CACHE"
    echo "V3C_STABLE=$V3C_STABLE"
    echo "V3C_OPTS=\"$V3C_OPTS\""
    echo "PROGRESS_ARGS=\"$PROGRESS_ARGS\""
    echo "AENEAS_TEST=\"$AENEAS_TEST\""
fi

if [ $# != 0 ]; then
    TEST_DIRS="$@"
else
    TEST_DIRS="unit asm/x86 asm/x86-64 redef core cast variants enums fsi32 fsi64 float range layout large pointer darwin linux rt stacktrace gc system lib wizeng apps bench"
fi

#######################################################################
# Run test configure script if it hasn't already been run
#######################################################################
if [ ! -e $VIRGIL_LOC/test/config/configged ]; then
    print_line
    $VIRGIL_LOC/test/configure
fi

#######################################################################
# Run unit and lib tests on stable
#######################################################################
for dir in unit lib; do
    if [[ ! "$TEST_DIRS" =~ "$dir" ]]; then
	continue # dir not in TEST_DIRS
    fi
    td=$VIRGIL_LOC/test/$dir
    print_line
    echo "${CYAN}($V3C_STABLE) $dir${NORM}"
    (cd $td && AENEAS_TEST=$V3C_STABLE $td/test.bash) || exit $?
done

#######################################################################
# Compile Aeneas with stable compiler
#######################################################################
CURRENT=$VIRGIL_TEST_OUT/aeneas/current/$TEST_HOST/Aeneas
if [ "$AENEAS_TEST" = auto ]; then
    compile_aeneas $V3C_STABLE $VIRGIL_TEST_OUT/aeneas/bootstrap $TEST_HOST
    BOOTSTRAP=$VIRGIL_TEST_OUT/aeneas/bootstrap/$TEST_HOST/Aeneas
    export AENEAS_TEST=$BOOTSTRAP
fi


#######################################################################
# Run first round of tests
#######################################################################
for dir in $TEST_DIRS; do
    td=$VIRGIL_LOC/test/$dir
    print_line
    echo "${CYAN}($AENEAS_TEST) $dir${NORM}"
    (cd $td && $td/test.bash) || exit $?
done

if [ "$SKIP_BOOTSTRAP" = 1 ]; then
    exit $EXIT_SUCCESS
fi


#######################################################################
# Bootstrap check
#######################################################################
compile_aeneas $BOOTSTRAP $VIRGIL_TEST_OUT/aeneas/current $TEST_HOST
diff -rq $VIRGIL_TEST_OUT/aeneas/bootstrap/ $VIRGIL_TEST_OUT/aeneas/current/ > $OUT/bootstrap.diff
if [ $? = 0 ]; then
    # binaries match exactly. no need to test again
    echo "  bin/current == bin/bootstrap ${GREEN}ok${NORM}"
    exit $EXIT_SUCCESS
else
    # if the bootstrap check fails, print out the diff
    printf $YELLOW
    cat $OUT/bootstrap.diff
    printf $NORM
fi

#######################################################################
# Run all tests again if bootstrap check failed
#######################################################################
for dir in $TEST_DIRS; do
    td=$VIRGIL_LOC/test/$dir
    print_line
    echo "${CYAN}($CURRENT) $dir${NORM}"
    (cd $td && AENEAS_TEST=$CURRENT $td/test.bash) || exit $?
done

exit $EXIT_SUCCESS
