#!/bin/bash
set -euo pipefail
# Script to install dependencies inside an apptainer container.
#
# Installs uv, vllm, and lighteval to the container local home directory.
# Requires VIRTUAL_ENV to be set by apptainer.
#
# Result: uv install + a venv directory with Python dependencies in the container home directory.
# https://github.com/vllm-project/vllm/issues/31018

if [[ -z "${VIRTUAL_ENV:-}" ]]; then
    echo "VIRTUAL_ENV must be set before running this script" >&2
    exit 1
fi

curl -LsSf https://astral.sh/uv/install.sh | sh

# export PATH="$HOME/.local/bin:$PATH"

echo "Using uv to set up Python environment at $VIRTUAL_ENV"
uv venv "$VIRTUAL_ENV" --python python3.11.5
source "$VIRTUAL_ENV/bin/activate"

uv sync

echo Inside singularity shell, run:
echo hf auth login
