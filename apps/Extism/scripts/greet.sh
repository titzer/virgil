#!/usr/bin/env bash
set -ex
extism call greet/Greet.wasm greet --wasi --input "$@"
