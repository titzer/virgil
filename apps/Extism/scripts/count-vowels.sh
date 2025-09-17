#!/usr/bin/env bash
set -ex
extism call count-vowels/CountVowels.wasm count_vowels --wasi --input "$@"
