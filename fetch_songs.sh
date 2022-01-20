#!/bin/bash

# Fetches and converts all songs from https://github.com/robsoncouto/arduino-songs

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

git clone https://github.com/robsoncouto/arduino-songs

mkdir -p "${SCRIPT_DIR}/programs/data/songs/"

for f in ./arduino-songs/*/*.ino
do
    echo "Converting: $f"
    filename=${f##*/}
    python3 "${SCRIPT_DIR}/song_converter.py" -m arduino $f "${SCRIPT_DIR}/programs/data/songs/${filename%.*}.bin"
done

rm -rf ./arduino-songs
