#!/bin/bash
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

VIRGIL_LOC="${DIR}/../.."
TEST_DIR="${VIRGIL_LOC}/apps/MicroLICM"

# Check necessary commands are installed
if [ "$(type -t nasm)" = "" ]; then
    echo "Install nasm"
    sudo apt -y install nasm
fi
if [ "$(type -t hyperfine)" = "" ]; then
    echo "Install hyperfine"
    sudo apt -y install hyperfine 
fi

TMP_DIR="/tmp/licm-microbench"

# Remove old executables 
if [ -d "${TMP_DIR}/default/licm-microbench" ]; then 
    rm "${TMP_DIR}/default/licm-microbench"
fi

if [ -d "${TMP_DIR}/licm/licm-microbench" ]; then 
    rm "${TMP_DIR}/licm/licm-microbench"
fi

if [ -e "${TMP_DIR}/results.json" ]; then 
    rm "${TMP_DIR}/results.json"
fi
echo "Directories cleaned"

mkdir -p "${TMP_DIR}"
mkdir -p "${TMP_DIR}/default"
mkdir -p "${TMP_DIR}/licm"


compile() {
    local runLICM=$1
    local dest=$2
    if [[ -e "${VIRGIL_LOC}/bin/v3c-x86-64-linux" ]]; then 
        echo "Found current Aeneas"
        CURRENT="${VIRGIL_LOC}/bin/v3c-x86-64-linux"
        if [ $runLICM = "true" ]; then 
            echo "Compiling with LICM | Executable destination: ${dest}"
            $CURRENT -licm -output=${dest} ${TEST_DIR}/licm-microbench.v3
        else 
            echo "Compiling without LICM | Executable destination: ${dest}"
            $CURRENT -output=${dest} ${TEST_DIR}/licm-microbench.v3
        fi
    else 
        echo "Current Aeneas not found"
        $DEV clean
        exit 1
    fi
}

echo "Compiling"
DEV="${VIRGIL_LOC}/bin/dev/aeneas"
$DEV clean
compile "false" "${TMP_DIR}/default/"
$DEV bootstrap
compile "true" "${TMP_DIR}/licm/"
$DEV clean

hyperfine --export-json ${TMP_DIR}/results.json "${TMP_DIR}/default/licm-microbench" "${TMP_DIR}/licm/licm-microbench" --runs=3

DEFAULT_MEAN=$(jq -r '.results[0].mean' ${TMP_DIR}/results.json)
LICM_MEAN=$(jq -r '.results[1].mean' ${TMP_DIR}/results.json)

if [[ ${DEFAULT_MEAN} > ${LICM_MEAN} ]]; then 
    echo "Success! | Default mean, ${DEFAULT_MEAN}, is larger than LICM mean, ${LICM_MEAN}."
    exit 0
else 
    echo "Failure | LICM mean, ${LICM_MEAN}, is larger than Default mean, ${DEFAULT_MEAN}."
    exit 1    
fi
