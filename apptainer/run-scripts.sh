#!/bin/bash
set -euo pipefail
# runs evaluation in custom virtual environments with some default arguments
# first argument is model name
# the rest of the arguments are passed to the python evaluation runner

ALL_ARGS="$*"
echo "All arguments: $ALL_ARGS"

# if you are not using uv, activate the venv manually. Make sure to set VIRTUAL_ENV before running this script.
# source "${VIRTUAL_ENV:-$HOME/venv}/bin/activate"

# if you are using uv, sync the environment to make it available in the current shell session
# use uv with specific python version and sync it
echo "Using uv to set up Python environment"
uv use python3.11.5
uv sync

# run your script whetehr with using uv
# uv run python .... $ALL_ARGS

# or using active venv
# python ... $ALL_ARGS
