#!/bin/bash
src="${BASH_SOURCE[0]}"
base_dir="$( cd -P "$( dirname "$src" )/.." >/dev/null 2>&1 && pwd )"
test_dir="${base_dir}/test"
tmp_dir="/tmp"
prog_bin="${base_dir}/progress"
out_file="${tmp_dir}/actual.out"
exp_file="${test_dir}/v3-expected.out"
diff_file="${tmp_dir}/actual.diff"

BLUE="\033[0;34m"
GREEN="\033[0;32m"
RED="\033[0;31m"
NORM="\033[0;00m"

function check() {
    if [ $1 == 0 ]; then
        echo -e "${GREEN}ok${NORM}"
    else
        echo -e "${RED}failed${NORM}"
    fi
}

rm -rf ${out_file}

for t in $( ls -1 ${test_dir}/*.txt ) ; do
    ${prog_bin} i < "${t}" &>> ${out_file}
    ${prog_bin} c < "${t}" &>> ${out_file}
    ${prog_bin} l < "${t}" &>> ${out_file}
    ${prog_bin} s < "${t}" &>> ${out_file}
done;

diff -u "${exp_file}"  "${out_file}" > "${diff_file}"
X=$?
check $X

if [ $X != 0 ]; then
    echo -e "${BLUE}test: ${diff_file}${NORM}"
    head -n 10 "${diff_file}"
    exit 1
else
    rm -rf "${out_file}"
    rm -rf "${diff_file}"
    exit 0
fi
