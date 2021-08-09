#!/bin/bash

PROGRESS_PIPE=1
if [ "$1" = "-fatal" ]; then
    PROGRESS_PIPE=0
fi

v3c *.v3 $(cat DEPS)
if [ "$?" -ne 0 ]; then
    exit 1
fi

if [ "$PROGRESS_PIPE" = 1 ]; then
    v3c $V3C_OPTS -run *.v3 $(cat DEPS) $@ | progress i
else
    v3c $V3C_OPTS -run *.v3 $(cat DEPS) $@
fi
