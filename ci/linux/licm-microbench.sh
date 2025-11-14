#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/apps/MicroLICM"

if [ "$(type -t nasm)" = "" ]; then
    echo "Install nasm"
    sudo apt -y install nasm
fi
TMP_DIR="/tmp/licm-microbench"

if [ -f "${TMP_DIR}/default/licm-microbench" ]; then 
    rm "${TMP_DIR}/default/licm-microbench"
fi

if [ -f "${TMP_DIR}/licm/licm-microbench" ]; then 
    rm "${TMP_DIR}/licm/licm-microbench"
fi

if [ -f "${TMP_DIR}/results.json" ]; then 
    rm "${TMP_DIR}/results.json"
fi

mkdir -p "${TMP_DIR}"
mkdir -p "${TMP_DIR}/default"
mkdir -p "${TMP_DIR}/licm"

echo "$@ -output=${TMP_DIR}/default"

v3c-x86-64-linux $@ -O2 -output=${TMP_DIR}/default/ ${TEST_DIR}/licm-microbench.v3
v3c-x86-64-linux $@ -O2 -licm -output=${TMP_DIR}/licm/ ${TEST_DIR}/licm-microbench.v3

hyperfine --export-json ${TMP_DIR}/results.json "${TMP_DIR}/default/licm-microbench" "${TMP_DIR}/licm/licm-microbench" --runs=3

DEFAULT_MEAN=$(jq -r '.results[0].mean' ${TMP_DIR}/results.json)
LICM_MEAN=$(jq -r '.results[1].mean' ${TMP_DIR}/results.json)

echo "DEFAULT_MEAN ${DEFAULT_MEAN}"
echo "LICM_MEAN ${LICM_MEAN}"

if [[ ${DEFAULT_MEAN} > ${LICM_MEAN} ]]; then 
    echo "Default mean, ${DEFAULT_MEAN}, is larger than LICM mean, ${LICM_MEAN}."
    exit 0
else 
    echo "LICM mean, ${LICM_MEAN}, is larger than Default mean, ${DEFAULT_MEAN}."
    exit 1    
fi
