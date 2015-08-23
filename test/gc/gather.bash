#!/bin/bash

for f in execute variants large; do
  v3c -test -test.gc=$f.gc ../$f/*.v3
done
