#!/usr/bin/env bash

. ../common.bash annotations

# Annotations are gated behind an unstable language flag, and the standard annotation
# declarations are supplied explicitly, as the platform wrappers do for real programs.
# Comma-separated so the value survives the word splitting of $V3C_OPTS.
ANN_FILES=$(echo $VIRGIL_LOC/lib/annotations/*.v3 | tr " " ",")
V3C_OPTS="$V3C_OPTS -lang:annotations -lang.annotation-files=$ANN_FILES"

do_parser_tests
do_seman_tests
