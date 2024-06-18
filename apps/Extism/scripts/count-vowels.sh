#!/bin/bash -ex
extism call count-vowels/CountVowels.wasm count_vowels --wasi --input "$@"
