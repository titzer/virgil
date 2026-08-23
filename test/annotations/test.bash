#!/usr/bin/env bash

. ../common.bash annotations

# Annotations are gated behind an unstable language flag.
V3C_OPTS="$V3C_OPTS -lang:annotations"

do_parser_tests
