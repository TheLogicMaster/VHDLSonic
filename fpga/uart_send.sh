#!/bin/bash

# Hacky way to send data to FPGA UART over JTAG using the nios2-terminal program

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/env.sh"

echo "$@" | "${QUARTUS_DIR}/nios2-terminal${EXT}" &> /dev/null &
sleep 2 && kill $! 2>&-
