#!/bin/bash -ex
v3c \
  -entry-export=_initialize \
  -heap-size=500m \
  -main-export=_initialize \
  -output=greet \
  -target=wasm \
  greet/Greet.v3 $(cat DEPS)
