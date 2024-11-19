#!/bin/bash -ex
extism call greet/Greet.wasm greet --wasi --input "$@"
