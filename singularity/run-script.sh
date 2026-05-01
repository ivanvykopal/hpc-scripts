#!/bin/bash
set -euo pipefail
# runs evaluation in custom virtual environments with some default arguments
# all arguments are passed to the python evaluation runner

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 [args...]" >&2
    exit 1
fi

echo "Running with args: $*"

if [[ -n "${VIRTUAL_ENV:-}" && -f "$VIRTUAL_ENV/bin/activate" ]]; then
    # Use the container-local virtual environment created by 03_install-vllm.sh.
    source "$VIRTUAL_ENV/bin/activate"
fi

python eval_vllm.py "$@"
