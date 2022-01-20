#!/bin/bash

# Converts all tile images to binary formats

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

for f in ./programs/data/chip8/*.ch8
do
    python3 "${SCRIPT_DIR}/header_generator.py" "${f}"
done
