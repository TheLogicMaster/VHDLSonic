#!/bin/bash

# Source this file to load project environment variables

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

PROJECT="${SCRIPT_DIR}"

if grep -q Microsoft /proc/version; then
  # WSL variables
  QUARTUS_DIR_EXT='C:\intelFPGA_lite\20.1\quartus\bin64'

  QUARTUS_DIR="$(wslpath "${QUARTUS_DIR_EXT}")"
  EXT=".exe"
  PROJECT_EXT="$(wslpath -m "${PROJECT}")"
else
  # Linux variables
  QUARTUS_DIR=/mnt/Storage/Syncronized/Programs/Linux/Quartus-Prime/quartus/bin

  EXT=""
  QUARTUS_DIR_EXT="${QUARTUS_DIR}"
  PROJECT_EXT="${PROJECT}"
fi
