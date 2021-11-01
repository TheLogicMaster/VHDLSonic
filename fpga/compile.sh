 #!/bin/bash

# Compiles the project

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/env.sh"

(
    cd "${PROJECT}"

    "${QUARTUS_DIR}/quartus_map${EXT}" fpga --optimize=area
    "${QUARTUS_DIR}/quartus_sh${EXT}" --flow compile fpga
)
