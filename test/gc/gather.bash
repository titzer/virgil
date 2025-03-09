#!/bin/bash

for f in core cast variants range large; do
    v3c -test -test.gc=/tmp/$f.gc ../$f/*.v3
    sort /tmp/$f.gc > $f.gc
done
