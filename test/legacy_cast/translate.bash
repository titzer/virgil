#!/bin/bash

for f in "$@"; do
    echo $f
    cp $f ${VIRGIL_LOC}/test/legacy_intcast/
    sed -i  -es/[.]\\!/.view/g $f
    git diff $f
    v3c-dev -test $f
done
