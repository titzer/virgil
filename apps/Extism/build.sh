#!/bin/bash -ex
v3c \
  -entry-export=_initialize \
  -heap-size=500m \
  -main-export=_initialize \
  -output=greet \
  -target=wasm \
  greet/Greet.v3 $(cat DEPS)

v3c \
  -entry-export=_initialize \
  -heap-size=500m \
  -main-export=_initialize \
  -output=count-vowels \
  -target=wasm \
  count-vowels/CountVowels.v3 $(cat DEPS)

v3c \
  -entry-export=_initialize \
  -heap-size=500m \
  -main-export=_initialize \
  -output=http-get \
  -target=wasm \
  http-get/HttpGet.v3 $(cat DEPS)
