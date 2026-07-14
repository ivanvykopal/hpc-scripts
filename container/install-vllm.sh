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

# echo "Using nattive venv to set up Python environment at $VIRTUAL_ENV"
# python -m venv "$VIRTUAL_ENV"
# source "$VIRTUAL_ENV/bin/activate"

echo "Using uv to set up Python environment"
uv use python3.11.5
uv sync

echo Inside apptainer shell, run:
echo hf auth login
