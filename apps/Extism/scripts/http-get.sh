#!/bin/bash -ex
extism call \
    target/wasm/release/build/examples/http-get/http-get.wasm \
    http_get \
    --wasi \
    --allow-host='*.typicode.com'
