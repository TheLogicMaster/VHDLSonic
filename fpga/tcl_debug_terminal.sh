#!/bin/bash

# Setup TCL interface for debugging

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/env.sh"

(
    cd "${PROJECT}"
    "${QUARTUS_DIR}/quartus_stp${EXT}" -s
)
