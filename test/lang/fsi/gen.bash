#!/bin/bash

# gen all 1 <= L <= 64
function gen_l() {
  file=$1
  l=1
  while [ $l -lt 65 ]; do
    sed "-es/\$L/$l/g" $file > "_${file}_$l.v3"
    l=$((l + 1))
  done
}

# gen all (L, U) pairs where U > L
function gen_lu() {
  file=$1
  l=1
  while [ $l -lt 64 ]; do
    u=$(($l + 1))
    while [ $u -lt 64 ]; do
      sed "-es/\$L/$l/g" $file | sed "-es/\$U/$u/g" > "_${file}_${l}_${u}.v3"
      u=$((u + 1))
    done
    l=$((l + 1))
  done
}

for f in $*; do
    grep -q '\$U' $f
    if [ "$?" = "0" ]; then
	echo $f;
	gen_lu $f
	continue
    fi

    grep '\$L' $f &> /dev/null
    if [ "$?" = "0" ]; then
	echo $f;
	gen_l $f
    fi
done
