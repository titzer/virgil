#!/bin/bash -ex
extism call \
    http-get/HttpGet.wasm \
    http_get \
    --wasi \
    --allow-host='*.typicode.com'
