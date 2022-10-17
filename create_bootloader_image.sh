#!/bin/bash

# Create an SD card image for a list of programs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

out_file="${SCRIPT_DIR}/programs/build/bootloader_sd.img"
rm -rf "${out_file}"

(
    cd "${SCRIPT_DIR}/programs" || exit -1

    for file in "$@"; do
        if [[ "${file}" == *.c ]]; then
            type="c"
        elif [[ "${file}" == *.bas ]]; then
            type="basic"
        else
            type="assembly"
        fi
        python "${SCRIPT_DIR}/assembler.py" -t "${type}" -m "${file}" || exit -1

        echo -n -e "${file%.*}\x00" >> "${out_file}"
    done

    dd if=/dev/null of="${out_file}" bs=1 count=1 seek=512

    for file in "$@"; do
        cat "${SCRIPT_DIR}/programs/build/${file%.*}.img" >> "${out_file}"
    done
)
