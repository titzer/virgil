#!/usr/bin/env bash

. ../common.bash annotations

# ANN_FILES=$(echo $VIRGIL_LOC/lib/annotations/*.v3)
# V3C_OPTS="$V3C_OPTS -lang:annotations -lang.annotation-files=$ANN_FILES"
V3C_OPTS="$V3C_OPTS -lang:annotations"

do_parser_tests
# do_seman_tests
