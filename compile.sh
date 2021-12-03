#!/bin/bash

# Assemble/compile all programs in programs directory

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

(
    cd "${SCRIPT_DIR}/programs" || exit -1

    for f in ./*.asm
    do
        echo "Assembling: $f"
        python ../assembler.py "$f"
    done

    for f in ./*.c
    do
        echo "Compiling: $f"
        python ../assembler.py "$f" -t c
    done

    for f in ./*.bas
    do
        echo "Compiling: $f"
        python ../assembler.py "$f" -t basic
    done
)
