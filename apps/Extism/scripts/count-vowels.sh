#!/bin/bash -ex
extism call target/wasm/release/build/examples/count-vowels/count-vowels.wasm count_vowels --wasi --input "$@"
